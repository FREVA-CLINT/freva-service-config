# Freva services

This repository holds all definitions for Docker images to create services
that are needed to run Freva in production and development mode. Currently
those services are:

- MySQL
- MongoDB
- Apache Solr
- Redis
- Keycloak Open ID Connect service via OpenLDAP federation

## Production Usage
> [!CAUTION]
> A manual setup of the service will most likely fail. You should set up this
> service via the [freva-deployment](https://freva-deployment.readthedocs.io/en/latest/)
> routine.

## Development Usage
Development environments should submodule this repository. See the
[freva-nextgen](https://github.com/FREVA-CLINT/freva-nextgen) as an example.

## Keycloak
For development purpupose [Keycloak](https://www.keycloak.org) is pre configured
as an identity provider.
The keycloak configuration defines a *freva* realm. The realm defines a
``client_id=freva``. This freva realm has also
and openLDAP server configured. The openLDAP server configuration defines a
couple of dummy users:

- uid: johndoe, password: johndoe123, mail: john@example.com
- uid: janedoe, password: janedoe123, mail: jane@example.com
- uid: alicebrown, password: alicebrown123, mail: alice@example.com
- uid: bobsmith, password: bobsmith123, mail: bob@example.com
- uid: lisajones, password: lisajones123, mail: lisa@example.com
- uid: bobsmith, password: bobsmith123, mail: bob@existing.com

### Backup of data
If you need a simple backup functionality, you can add the `daily_backup.sh`
script in the same manner.

Setting up the volumes as outlined above will instruct the containers to
automatically creating new MariaDB tables (if not existing) and Solr cores
(if not existing).


If you added the `daily_backup.sh` files via a volume to the container you can
setup simple crontab to create backups on the *host* machine running
the container. A simple crontab example could like like this.

```
# m    h    dom   mon    dow      command
0      5    *     *      *        docker exec container-name bash -c /usr/local/bin/daily_backup
```
