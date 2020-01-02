import os

import git

def format_commit(commit):
  return f'{commit.hexsha[:7]} by {commit.author} on {commit.authored_datetime}: {commit.summary}'

class PullResult(object):
  def __init__(self, path, options):
    self.name = os.path.basename(path)
    self.path = path
    self.log = ''

    if options.verbose:
      print(f'Checking {path} for changes')
    repo = git.Repo(path)
    repo.remotes.origin.fetch()
    head = repo.head.ref
    tracking = head.tracking_branch()
    self.commits = list(tracking.commit.iter_items(repo, f'{head.path}..{tracking.path}'))
    if self.commits:
      if options.verbose:
        print(f'  {len(self.commits)} new commits found')
      if not options.dry_run:
        self.log = repo.git.merge()

def check_repos(options):
  changed = []
  for repo in os.listdir(options.repos):
    res = PullResult(os.path.join(options.repos, repo), options)
    if res.commits:
      changed.append(res)
  return changed
