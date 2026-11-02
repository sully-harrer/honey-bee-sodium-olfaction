# Releasing a version

Each release is a git tag that Zenodo archives with a DOI. The paper cites the **concept DOI**, which
always resolves to the newest version. Each version also gets its own DOI.

## One-time setup

1. Log in to [Zenodo](https://zenodo.org) with GitHub.
2. In Zenodo, open the **GitHub** page from your account menu and switch on `sully-harrer/honey-bee-sodium-olfaction`.
   Zenodo archives every GitHub *release* from then on (a tag alone is not enough).

## Before every release

1. Run the full pipeline from a clean state and check the output:
   ```r
   renv::status()       # should report no problems
   source("R/main.R")
   ```
2. Restore any figure PDFs whose only change is the embedded creation date:
   `git restore plots/<file>.pdf`.
3. Restyle and lint (see the Development section of `README.md`).
4. List the remaining placeholders and fill in the ones due for this release:
   `grep -rn "TODO(submission)" .`
5. Update `CITATION.cff`: `version`, `date-released`, and (from the second release on) `doi`.

## At submission (v1.0.0)

1. Commit, then tag and push:
   ```
   git tag -a v1.0.0 -m "Version submitted for review"
   git push origin main --tags
   ```
2. On GitHub, create a release from the `v1.0.0` tag. Zenodo archives it within a few minutes.
3. On the Zenodo record, check the metadata (authors, title, license) and copy the **concept DOI**
   ("Cite all versions").
4. Put the concept DOI in `CITATION.cff` (`doi`, `date-released`), the badge and data availability
   statement in `README.md`, and the manuscript. Commit this as a follow-up; it doesn't need a new release.

### Journals with double-anonymous review

If the journal hides author identities from reviewers, don't give reviewers the GitHub or Zenodo link
directly, because both show the author's name. Use one of these instead:

- An anonymized copy of the GitHub repository from [Anonymous GitHub](https://anonymous.4open.science),
  which removes names and links you specify.
- A Zenodo record with restricted access, shared through a link that doesn't identify the author.

Check the journal's author guidelines for which it expects.

### Behavioral Ecology

Behavioral Ecology asks for the data to be archived and the link given **at submission**, and its data
editor checks the archive before acceptance. Make the v1.0.0 release before submitting.

## After revisions or acceptance

1. Make the changes, rerun the pipeline, and repeat "Before every release".
2. Bump the version in `CITATION.cff` (e.g. `1.1.0` after revisions, `2.0.0` if results change) and tag
   it the same way (`v1.1.0`).
3. Create the GitHub release. Zenodo adds it as a new version under the same concept DOI.
4. Once the paper is published, fill in `preferred-citation` in `CITATION.cff` (journal, year, volume,
   DOI) and add the citation to `README.md`.
