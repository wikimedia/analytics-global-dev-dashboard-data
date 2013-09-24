import json
import os
import sys
import pprint
from operator import itemgetter
import re
import yaml

basedir = sys.argv[1]

# find dashboards
dashboard_paths = []
for (path, dirs, files) in os.walk(os.path.join(basedir,'dashboards')):
    for f in files:
        dashboard_paths.append(os.path.join(path,f))

graph_ids = []
for dashboard_path in dashboard_paths:
    db = json.load(open(dashboard_path))
    db_graph_ids = reduce(list.__add__, map(itemgetter('graph_ids'), db['tabs']), [])
    graph_ids.extend(db_graph_ids)
# print 'graph_ids: %s' % graph_ids

# find graphs
graph_paths = []
for (path, dirs, files) in os.walk(os.path.join(basedir,'graphs')):
    for f in files:
        graph_paths.append((f, os.path.join(path,f)))
# print 'graph_paths: %s' % graph_paths
graph_path_keepers = []
datasource_ids = []
for fname, graph_path in graph_paths:
    m = re.match('(.*).json', fname)
    if m:
        # print 'm.groups: %s' % m.groups()
        graph_id = m.groups(1)[0]
        if graph_id in graph_ids:
            try:
                g = json.load(open(graph_path))
                g_datasources = map(itemgetter('source_id'), g['data']['metrics'])
                datasource_ids.extend(g_datasources)
                graph_path_keepers.append(graph_path)
            except IOError:
                print 'could not locate: %s' % graph_path
                continue
# print 'datasource_ids: %s' % datasource_ids


source_paths = []
for (path, dirs, files) in os.walk(os.path.join(basedir,'datasources')):
    for f in files:
        source_paths.append((f, os.path.join(path,f)))
# print 'source_paths: %s' % source_paths
source_path_keepers = []
datafile_paths = []
for fname, source_path in source_paths:
    m = re.match('(.*).yaml', fname)
    if m:
        # print 'm.groups: %s' % m.groups()
        # NOTE THAT THIS ASSUMED ID AND FILE NAME ARE IDENTICAL!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        source_id = m.groups(1)[0]
        if source_id in datasource_ids:
            try:
                source = yaml.load(open(source_path))
                source_path_keepers.append(source_path)
                datafile_url = source['url']
                m = re.match('/data/datafiles/(.*)', datafile_url)
                if m:
                    datafile_paths.append(os.path.join(basedir, 'datafiles', m.groups(1)[0]))
            except:
                raise

# print dashboard_paths
# print graph_path_keepers
# print source_path_keepers
# print datafile_paths

keepers = dashboard_paths + graph_path_keepers + source_path_keepers + datafile_paths

all_paths = []
for (path, dirs, files) in os.walk(os.path.join(basedir)):
    for f in files:
        full = path.split('/') + [f]
        if '.git' not in full and f != 'necessary.py':
            all_paths.append(os.path.join(path,f))

all_paths = set(all_paths)
keepers = set(keepers)

not_found = keepers - all_paths
unnecessary = all_paths - keepers

# print 'keepers: %d' %  len(keepers)
# print 'all_paths: %s' % len(all_paths)
# print 'unnecessary: %d' % len(unnecessary)
# print 'not_found: %d' % len(not_found)

print ' '.join(unnecessary)
