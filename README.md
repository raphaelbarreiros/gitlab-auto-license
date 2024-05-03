# Description

This is a script that installs a GitLab Ultimate license on your self-hosted instance.

Tested on:
- GitLab running on Docker

### Requirements
[jq](https://jqlang.github.io/jq/download/ "jq") (apt-get install jq)
GitHub token (to be placed on github-token file)

### How-to
1. Copy the gitlab-auto-license.sh to your docker instance
2. Copy/create a file named github-token and put it on the same folder as the previous file
3. Create a fine-grained [GitHub personal access token](https://github.com/settings/tokens "GitHub personal access token")
4. Paste the token in the github-token file
5. Run gitlab-auto-license.sh
6. Enjoy!

### Thanks
That wouldnt be possible without the [Lakr233/GitLab-License-Generator](https://github.com/Lakr233/GitLab-License-Generator "Lakr233/GitLab-License-Generator") repo builds