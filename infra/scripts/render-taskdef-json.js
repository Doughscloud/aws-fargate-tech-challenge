#!/usr/bin/env node
const fs = require('fs');
const args = require('minimist')(process.argv.slice(2));
function parseEnvList(s){ if(!s) return []; return s.split(',').map(kv=>{ const [k,...r]=kv.split('='); return {name:k.trim(), value:r.join('=').trim()}; }); }
const base = JSON.parse(fs.readFileSync(__dirname + '/sample-taskdef-base.json','utf8'));
base.family = args.family || base.family;
base.cpu = String(args.cpu || base.cpu);
base.memory = String(args.memory || base.memory);
base.executionRoleArn = args.execRole || base.executionRoleArn;
base.taskRoleArn = args.taskRole || base.taskRoleArn;
const c = base.containerDefinitions[0];
c.name = args.name || c.name;
c.image = args.image || c.image;
c.portMappings[0].containerPort = Number(args.port || 80);
c.logConfiguration.options['awslogs-group'] = args.logGroup || c.logConfiguration.options['awslogs-group'];
c.logConfiguration.options['awslogs-region'] = args.region || c.logConfiguration.options['awslogs-region'];
c.environment = parseEnvList(args.env || '');
process.stdout.write(JSON.stringify(base,null,2));
