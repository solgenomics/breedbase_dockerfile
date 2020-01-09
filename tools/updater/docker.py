from datetime import datetime
import subprocess
import docker

def stream_to_map(stream):
  m = {}
  for entry in stream:
    for k, v in entry.items():
      m.setdefault(k, []).append(v)
  return m

def update_docker(options):
  now = datetime.utcnow()
  tag = now.strftime("%y%m%d-%H%M%S")
  if options.verbose:
    print(f'Building docker image {options.image_name}:{tag}…')
  if options.use_docker_py:
    client = docker.from_env()
    try:
      image, logs = client.images.build(path=options.root, rm=True, tag=f'{options.image_name}:{tag}')
    except docker.errors.BuildError as e:
      return {'error': 1, 'tag': None, 'id': None, 'logs': stream_to_map(e.build_log), 'error_msg': e.msg}
    image.tag(f'{options.image_name}:latest')
    return {'error': 0, 'tag': tag, 'id': image.id.split(':', 1)[1][:12], 'logs': stream_to_map(logs)}
  else:
    res = subprocess.run(['docker', 'build', '-t', f'{options.image_name}:{tag}', options.root], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    logs = {'docker_build_out': [res.stdout.decode(sys.stdout.encoding)], 'docker_build_err': [res.stderr.decode(sys.stdout.encoding)]}
    if res.returncode:
      return {'error': res.returncode, 'tag': None, 'id': None, 'logs': logs}
    res = subprocess.run(['docker', 'tag', f'{options.image_name}:{tag}', f'{options.image_name}:latest'], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    logs.update({'docker_tag_out': [res.stdout.decode(sys.stdout.encoding)], 'docker_tag_err': [res.stderr.decode(sys.stdout.encoding)]})
    return {'error': res.returncode, 'tag': tag, 'id': None, 'logs': logs}
