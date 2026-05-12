load("@bazel_tools//tools/build_defs/repo:utils.bzl", "read_netrc", "read_user_netrc", "use_netrc")


def load_netrc(ctx, use_netrc_credentials):
    """Load a netrc file if netrc auth is enabled.

    Args:
        ctx: repository or module context.
        use_netrc_credentials: bool.
            - False: do not load any netrc data.
            - True: use $NETRC if present, otherwise ~/.netrc.

    Returns:
        Parsed netrc mapping suitable for use with `use_netrc`.
    """
    if use_netrc_credentials:
        if "NETRC" in ctx.os.environ:
            return read_netrc(ctx, ctx.os.environ["NETRC"])
        return read_user_netrc(ctx)
    return {}


def netrc_auth(ctx, urls, use_netrc_credentials, auth_patterns = {}):
    """Compute auth for URLs using netrc, honoring explicit disable.

    Args:
        ctx: repository or module context.
        urls: list of URLs to match against the netrc data.
        use_netrc_credentials: bool indicating whether to enable netrc auth.
        auth_patterns: optional auth pattern map for use_netrc.

    Returns:
        auth dict suitable for passing to ctx.download.
    """
    if not use_netrc_credentials:
        return {}
    return use_netrc(load_netrc(ctx, use_netrc_credentials), urls, auth_patterns)
