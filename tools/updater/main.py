from datetime import datetime
import os
from pathlib import Path
import subprocess
import sys

from .git import check_repos, format_commit
from .docker import update_docker

def main(options):
  error = 0

  if options.verbose:
    print(f'Checking repos in {options.repos}')
  if options.dry_run and options.verbose:
    print('  (dry run)')
  changed = check_repos(options)
  if changed:
    logs = {}
    print('Changed repos:')
    for result in changed:
      print(f'{result.name}: {len(result.commits)} new commits')
      print(f'  from: {format_commit(result.commits[-1])}')
      print(f'  to: {format_commit(result.commits[0])}')
      if result.log:
        logs['git/' + result.name] = [result.log]
        if options.verbose:
          print(result.log)
          print('=' * 80)
  elif options.force_build:
    print('No changes detected, but building anyway as requested')
  elif options.verbose:
    print('No changes.')

  if changed or options.force_build:
    if options.dry_run:
      print('Not building image (dry run)')
    else:
      docker_res = update_docker(options)
      logs.update(docker_res['logs'])
      if docker_res.get('error'):
        if docker_res.get('error_msg'):
          print(f'Error building docker image: {docker_res["error_msg"]}')
        else:
          print('Error building docker image')
        error = docker_res['error']
      else:
        print(f'Built {options.image_name}:{docker_res["tag"]} ({docker_res.get("id", "id not known")})')
      print('Produced logs:', ', '.join(docker_res['logs'].keys()))
      if options.verbose and docker_res['logs'].get('stream'):
        for line in docker_res['logs']['stream']:
          print(line.strip())
        print('=' * 80)
      elif options.verbose and docker_res['logs'].get('docker_build_out'):
        for line in docker_res['logs']['docker_build_out']:
          print(line.strip())
        print('=' * 80)

    if error:
      print('Not updating containers (error occurred)')
    elif options.dry_run:
      print('Not updating containers (dry run)')
    elif options.update_compose:
      os.chdir(options.compose_root)
      # Python 3.7
      #compose_res = subprocess.run(['docker-compose', 'up', '-d'], capture_output=True)
      compose_res = subprocess.run(['docker-compose', 'up', '-d'], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
      error = compose_res.returncode
      logs['compose'] = compose_res.stdout
      if compose_res.stderr.strip():
        logs['compose-err'] = compose_res.stderr
        print(compose_res.stderr.decode(sys.getdefaultencoding()))
      else:
        print('Containers updated.')
    elif options.verbose:
      print('Not updating containers (no --update_compose)')

    if options.write_logs:
      path = Path(options.write_logs)
      (path / 'git').mkdir(parents=True, exist_ok=True)
      log_timestamp = f'\n=========\n{datetime.now().isoformat(" ")}\n'
      for name, content in logs.items():
        fpath = path / f'{name}.log'
        if type(content) is bytes:
          with fpath.open('wb') as f:
            f.write(log_timestamp.encode('ascii'))
            f.write(content)
        elif type(content) is list and type(content[0]) is bytes:
          with fpath.open('wb') as f:
            f.write(log_timestamp.encode('ascii'))
            f.writelines(content)
        elif content:
          with fpath.open('w', encoding='utf-8') as f:
            f.write(log_timestamp)
            if type(content) is str:
              f.write(content)
            elif type(content) is list and type(content[0]) is str:
              f.writelines(content)
            else:
              import json
              json.dump(content, f, indent=2)

  return error
