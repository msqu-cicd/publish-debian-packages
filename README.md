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

## Notes

- `deb_files` is split on whitespace, so paths must not contain spaces.
- Packages are published to the Debian package registry of the
  `forgejo_user` account (the API owner).
- File names must follow the `name_version_arch.deb` scheme; the
  package name, version and architecture used for overwriting are
  parsed from the file name, not from the package control fields.
- Prefer pinning a tag or commit SHA in `uses:` instead of `@main`.

## Usage

```yaml
  - name: Upload Debian Packages
    uses: https://git.msqu.de/CICD/publish-debian-packages@main
    with:
      deb_files: 'path/to/package1.deb path/to/package2.deb'
      overwrite: false
      forgejo_user: ${{ secrets.FORGEJO_USER }}
      forgejo_token: ${{ secrets.FORGEJO_TOKEN }}
      forgejo_server_url: 'https://forgejo.example.com'
      dist: 'stable'
      component: 'main'
