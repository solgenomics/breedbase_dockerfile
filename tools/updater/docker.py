from datetime import datetime
import docker

def update_docker(options):
  now = datetime.utcnow()
  tag = now.strftime("%y%m%d-%H%M%S")
  client = docker.from_env()
  if options.verbose:
    print(f'Building docker image {options.image_name}:{tag}…')
  image, logs = client.images.build(path=options.root, rm=True, tag=f'{options.image_name}:{tag}')
  collected_logs = {}
  for entry in logs:
    for k, v in entry.items():
      collected_logs.setdefault(k, []).append(v)
  image.tag(f'{options.image_name}:latest')
  return {'tag': tag, 'id': image.id.split(':', 1)[1][:12], 'logs': collected_logs}
