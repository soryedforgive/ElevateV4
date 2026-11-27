# ElevateV4

ElevateV4 is the GitHub-hosted build of the supplied project, with the previous product branding and service-dependent loader paths removed.

## Loader

Use this loader only when the repository is **public**:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/soryedforgive/ElevateV4/main/init.lua", true))()
```

**Private-repository note:** GitHub raw URLs do not grant a Roblox client access to a private repository. The upload script can push to a private repo using your local Git credentials, but the in-game loader will not be able to fetch it unless you use an authenticated server-side proxy. Do not put a GitHub personal access token in this Lua source.

## Upload

1. Extract this ZIP.
2. Install Git for Windows and sign in to GitHub through Git Credential Manager.
3. Run `upload.bat` from the extracted `ElevateV4` folder.
4. It replaces the tracked contents of `soryedforgive/ElevateV4` on branch `main` with this folder and pushes a commit.

The script does not contain a GitHub token. Git will use your existing credential manager login or prompt you to authenticate.

## Local profiles

The updater refreshes source files when `version.txt` changes and keeps existing files in `profiles/` intact. First-time installs receive the included default profiles.

## Removed hosted services

The original online license/login and cloud-profile services are not part of this GitHub build. Config export/import and local profiles remain available; cloud profile browsing and publishing are not enabled.
