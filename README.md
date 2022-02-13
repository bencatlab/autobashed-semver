# autobashed-semver

Generate your next Semantic Version based on Conventional Commit, update whatever.json and bump Tag to Git repository, via Bash, for low dependency and saving precious seconds !

🚸 This action update the last commit to avoid creating another one.

🔰 **SUPPORT ONLY .JSON FILE** (for now)

---

## EXAMPLE
```yaml
name: AutoBashed SemVer Tag

on: push

jobs:
  generate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
        with:
          fetch-depth: 0

      - name: "Generate Next SemVer"
        id: version
        uses: bendevcat/autobashed-semver@main
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}

      - name: "Output SemVer from previous Step"
        run: echo "${{ steps.version.outputs.next-semver }}"
```

--- 

## WIP
  - Update any files
  - Option to define default version
  - Implement all conventional-commit wording
  - Option to handle patch in addition to major and minor
