load(":cargo_credentials.bzl", "load_cargo_credentials", "registry_auth")
load(":netrc.bzl", "netrc_auth")

def _registry_config_repository_impl(rctx):
    # TODO(zbarsky): Is there a better way than fetching this in every crate repository?
    url = rctx.attr.source.removeprefix("sparse+") + "config.json"
    auth = netrc_auth(rctx, [url], rctx.attr.use_netrc_credentials)

    # Fallback to cargo credentials if netrc did not yield any auth.
    if not auth and rctx.attr.use_home_cargo_credentials:
        auth = registry_auth(
            load_cargo_credentials(rctx, rctx.attr.cargo_config),
            rctx.attr.source,
            url
        )

    rctx.download(
        url,
        "config.json",
        auth = auth,
    )

    dl = json.decode(rctx.read("config.json"))["dl"]
    if not (
        "{crate}" in dl or
        "{version}" in dl or
        "{sha256-checksum}" in dl or
        "{prefix}" in dl or
        "{lowerprefix}" in dl
    ):
        dl += "/{crate}/{version}/download"

    rctx.file("dl", dl)
    rctx.file("BUILD.bazel", "exports_files(['dl'])")

    # Registry config can change upstream, so this repository is intentionally not reproducible.
    return rctx.repo_metadata(reproducible = False)

registry_config_repository = repository_rule(
    implementation = _registry_config_repository_impl,
    attrs = {
        "source": attr.string(mandatory = True),
        "cargo_config": attr.label(),
        "use_home_cargo_credentials": attr.bool(),
        "use_netrc_credentials": attr.bool(),
    },
)
