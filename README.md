# Upload Debian Packages

This Action uploads Debian packages to a Forgejo repository.

## Inputs

| Name                  | Description                                   | Required | Default                         |
|-----------------------|-----------------------------------------------|----------|---------------------------------|
| `deb_files`           | Paths to the .deb files to upload             | true     |                                 |
| `overwrite`           | Set to true to overwrite existing versions    | false    | `false`                         |
| `forgejo_user`        | Forgejo username                              | false    | `${{ github.repository_owner }}`|
| `forgejo_token`       | Forgejo token                                 | true     |                                 |
| `forgejo_server_url`  | Forgejo Server URL                            | false    | `${{ github.server_url }}`      |
| `dist`                | Distribution                                  | false    | `testing`                       |
| `component`           | Component                                     | false    | `main`                          |

## Usage

```yaml
  - name: Upload Debian Packages
    uses: https://git.msqu.de/cicd/publish_debian_packages.git@main
    with:
      deb_files: 'path/to/package1.deb path/to/package2.deb'
      overwrite: false
      forgejo_user: ${{ secrets.FORGEJO_USER }}
      forgejo_token: ${{ secrets.FORGEJO_TOKEN }}
      forgejo_server_url: 'https://forgejo.example.com'
      dist: 'stable'
      component: 'main'
