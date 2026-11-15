> **This file is a personal guide for preparing the release. 
> Delete it from the repository in the last commit before tagging v1.0.0, so it isn't archived on
> Zenodo. Follow the post-release steps from your copy.**

# Releasing a version

Each release is a git tag that Zenodo archives with a DOI. Every version gets its own **version DOI**,
and all versions share one **concept DOI** that always resolves to the newest version. The manuscript
cites the version DOI of the release that matches the paper. The README badge uses the concept DOI
("Cite all versions").

Zenodo reads only `.zenodo.json` when it and `CITATION.cff` both exist. `CITATION.cff` drives GitHub's
"Cite this repository" button. Keep the two in agreement by hand.

## One-time setup

1. Log in to [Zenodo](https://zenodo.org) with GitHub.
2. In Zenodo, open the **GitHub** page from your account menu and switch on `sully-harrer/honey-bee-sodium-olfaction`.
   Zenodo archives every GitHub *release* from then on (a tag alone is not enough).

## Before every release

1. Check the environment and run the full pipeline:
   ```r
   renv::status()       # should report no problems
   source("R/main.R")
   ```
2. Restore any figure PDFs whose only change is the embedded creation date:
   `git restore plots/<file>.pdf`.
3. Restyle and lint. `styler` and `lintr` are not in `renv.lock`, so install them separately:
   ```r
   styler::style_dir("R")
   lintr::lint_dir("R")
   ```
4. Search for leftover placeholders (none should remain):
   ```
   grep -rn "TODO\|XXXXXXX" . --exclude-dir=renv
   ```
5. Check that `CITATION.cff` and `.zenodo.json` agree on title, authors (order, ORCIDs,
   affiliations) and keywords, and that `version` in `CITATION.cff` matches the tag about to be made.

## At submission (v1.0.0)

v1.0.0 deliberately has no DOI placeholders: the README has no badge or data availability section, and
`CITATION.cff` has no `doi` or `date-released`. They are added after the DOI exists.

1. Finish every check in "Before every release".
2. Copy this file outside the repository, delete it, and commit.
3. Tag and push:
   ```
   git tag -a v1.0.0 -m "Version submitted for review"
   git push origin main --tags
   ```
4. On GitHub, create a release from the `v1.0.0` tag. Zenodo archives it within a few minutes.
5. On the new Zenodo record, check: resource type is dataset, license is CC BY 4.0, both creators
   have ORCIDs and affiliations, and the NSF GRFP award (2235783) is under funding.
6. Copy both the **version DOI** and the **concept DOI**.
7. In a follow-up commit, add the concept-DOI badge to `README.md`, and `doi` (the concept DOI) and
   `date-released` to `CITATION.cff`. Put the **version DOI** in the manuscript's data availability
   statement. This commit doesn't need a new release.

If the record's metadata is wrong, edit it on Zenodo, and fix `.zenodo.json` in the repository so the
next release is correct.

### Journals with double-anonymous review

If the journal hides author identities from reviewers, don't give reviewers the GitHub or Zenodo link
directly, because both show the author's name. Use one of these instead:

- An anonymized copy of the GitHub repository from [Anonymous GitHub](https://anonymous.4open.science),
  which removes names and links you specify.
- A Zenodo record with restricted access, shared through a link that doesn't identify the author.

Check the target journal's author guidelines for its review model and data availability statement
requirements.

## After revisions or acceptance

1. Make the changes and bump `version` in `CITATION.cff` (e.g. `1.1.0` after revisions, `2.0.0` if
   results change).
2. Rerun the checks in "Before every release".
3. Tag and create the GitHub release the same way (`v1.1.0`). Zenodo adds it as a new version under the
   same concept DOI.
4. If the paper's numbers depend on the new version, update the manuscript to the new version DOI.
5. Once the paper is published, add `preferred-citation` to `CITATION.cff`, and add this to
   `.zenodo.json` (before the next release) with the paper's DOI:
   ```json
   "related_identifiers": [
     {
       "identifier": "https://doi.org/<paper DOI>",
       "relation": "isSupplementTo",
       "resource_type": "publication-article"
     }
   ]
   ```
