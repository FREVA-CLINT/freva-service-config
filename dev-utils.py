"""Service utilities."""

import argparse
import datetime
import os
from pathlib import Path
import time
import urllib.request
import tempfile
from typing import Optional

try:
    from cryptography import x509
    from cryptography.hazmat.backends import default_backend
    from cryptography.hazmat.primitives import hashes, serialization
    from cryptography.hazmat.primitives.asymmetric import rsa
    from cryptography.x509.oid import NameOID
except ImportError:
    import pip

    pip.main(["install", "cryptography"])
    from cryptography import x509
    from cryptography.hazmat.backends import default_backend
    from cryptography.hazmat.primitives import hashes, serialization
    from cryptography.hazmat.primitives.asymmetric import rsa
    from cryptography.x509.oid import NameOID


def kill_proc(namespace: argparse.Namespace) -> None:
    """Kill a potentially running process."""

    if namespace.pid_file.is_file():
        try:
            pid = int(namespace.pid_file.read_text())
            os.kill(pid, 15)
            time.sleep(2)
            if os.waitpid(pid, os.WNOHANG) == (0, 0):
                os.kill(pid, 9)
        except (ProcessLookupError, ValueError, ChildProcessError):
            pass


def wait_for_oidc(namespace: argparse.Namespace) -> None:
    """Wait for openid connect server an exit."""
    time_passed = 0
    while time_passed < namespace.timeout:
        try:
            print(f"Trying {namespace.url}...", end="")
            conn = urllib.request.urlopen(namespace.url)
            print(f"{conn.status}")
            if conn.status == 200:
                return
        except Exception as error:
            print(error)
        time.sleep(namespace.time_increment)
        time_passed += namespace.time_increment
    raise SystemExit("Open ID connect service is not up.")


class RandomKeys:
    """Generate public and private server keys.

    Parameters:
        base_name (str): The path prefix for all key files.
        common_name (str): The common name for the certificate.
    """

    def __init__(
        self, base_name: str = "freva", common_name: str = "localhost"
    ) -> None:
        self.base_name = base_name
        self.common_name = common_name
        self._private_key_pem: Optional[bytes] = None
        self._public_key_pem: Optional[bytes] = None
        self._private_key: Optional["rsa.RSAPrivateKey"] = None

    @classmethod
    def gen_certs(cls, namespace: argparse.Namespace) -> None:
        """Generate a new pair of keys."""
        keys = cls()
        namespace.cert_dir.mkdir(exist_ok=True, parents=True)
        private_key_file = namespace.cert_dir / "client-key.pem"
        public_cert_file = namespace.cert_dir / "client-cert.pem"
        private_key_file.write_bytes(keys.private_key_pem)
        private_key_file.chmod(0o600)
        public_cert_file.write_bytes(keys.certificate_chain)

    @property
    def private_key(self) -> "rsa.RSAPrivateKey":
        if self._private_key is not None:
            return self._private_key
        self._private_key = rsa.generate_private_key(
            public_exponent=65537, key_size=2048, backend=default_backend()
        )
        return self._private_key

    @property
    def private_key_pem(self) -> bytes:
        """Create a new private key pem if it doesn't exist."""
        if self._private_key_pem is None:
            self._private_key_pem = self.private_key.private_bytes(
                encoding=serialization.Encoding.PEM,
                format=serialization.PrivateFormat.PKCS8,
                encryption_algorithm=serialization.NoEncryption(),
            )
        return self._private_key_pem

    @property
    def public_key_pem(self) -> bytes:
        """
        Generate a public key pair using RSA algorithm.

        Returns:
            bytes: The public key (PEM format).
        """
        if self._public_key_pem is None:
            public_key = self.private_key.public_key()
            self._public_key_pem = public_key.public_bytes(
                encoding=serialization.Encoding.PEM,
                format=serialization.PublicFormat.SubjectPublicKeyInfo,
            )
        return self._public_key_pem

    def create_self_signed_cert(self) -> "x509.Certificate":
        """
        Create a self-signed certificate using the public key.

        Returns
        -------
            x509.Certificate: The self-signed certificate.
        """
        certificate = (
            x509.CertificateBuilder()
            .subject_name(
                x509.Name([x509.NameAttribute(NameOID.COMMON_NAME, self.common_name)])
            )
            .issuer_name(
                x509.Name([x509.NameAttribute(NameOID.COMMON_NAME, self.common_name)])
            )
            .public_key(self.private_key.public_key())
            .serial_number(x509.random_serial_number())
            .not_valid_before(datetime.datetime.now(datetime.timezone.utc))
            .not_valid_after(
                datetime.datetime.now(datetime.timezone.utc)
                + datetime.timedelta(days=365)
            )
            .sign(self.private_key, hashes.SHA256(), default_backend())
        )

        return certificate

    @property
    def certificate_chain(self) -> bytes:
        """The certificate chain."""
        certificate = self.create_self_signed_cert()
        certificate_pem = certificate.public_bytes(serialization.Encoding.PEM)
        return self.public_key_pem + certificate_pem


def cli() -> None:
    """Command line interface."""
    app = argparse.ArgumentParser(
        description="Various utilities for development purpose.",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    app.set_defaults(cli=RandomKeys.gen_certs)
    subparser = app.add_subparsers(
        required=True,
    )
    key_parser = subparser.add_parser(
        name="gen-certs",
        help="Generate a random pair of public and private certificates.",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    key_parser.set_defaults(apply=RandomKeys.gen_certs)
    key_parser.add_argument(
        "--cert-dir",
        help="The ouptut directory where the certs should be stored.",
        type=Path,
        default=Path(__file__).parent / "certs",
    )
    oidc_parser = subparser.add_parser(
        name="oidc",
        help="Wait for the oidc service to start up.",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    oidc_parser.add_argument("url", help="Open ID connect discovery url.")
    oidc_parser.add_argument(
        "--timeout",
        type=int,
        default=500,
        help=(
            "The time out in s after which we should give up waiting for "
            "the service."
        ),
    )
    oidc_parser.add_argument(
        "--time-increment",
        type=int,
        default=10,
        help=(
            "Wait for <increment> seconds before attempting to contact the "
            "server again."
        ),
    )
    oidc_parser.set_defaults(apply=wait_for_oidc)
    kill_parser = subparser.add_parser(
        name="kill",
        help="Kill a running process.",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    kill_parser.add_argument(
        "pid-file", type=str, help="Path to the PID file holding the PID."
    )
    kill_parser.set_defaults(apply=kill_proc)
    args = app.parse_args()
    args.apply(args)


if __name__ == "__main__":
    cli()
