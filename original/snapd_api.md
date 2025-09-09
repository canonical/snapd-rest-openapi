mborzecki | 2024-06-12 11:17:30 UTC | #1

The REST API provides access to snapd's state and many of its key functions, as listed below.

For general information on how to use the API, including how to access it, its requests and responses, results fields and error types, see [Using the REST API](/t/using-the-rest-api/18603).

> As snapd development progresses, changes that are deemed backwards-compatible, such as adding methods or verbs, will not change an endpoint. Conversely, significant updates may necessitate a new endpoint being created.

The snapd REST API includes the following components:
|  |   |
|--|--|
| [aliases](#heading--aliases): get and modify  app aliases | [apps](#heading--apps): list and modify apps and their attributes |
| [assertions](#heading--assertions): list and add assertion types |[changes](#heading--changes): return the state and abort changes |
| [cohorts](#heading--cohorts): create and retrieve new cohort key | [configuration](#heading--snaps-name-conf): get and set snap options |
| [connections](#heading--connections): list all interface connections | [find](#heading--find): find snaps in the store |
| [icons](#heading--icon): retrieve the icon for an installed snap | [interfaces](#heading--interfaces): list interfaces and their metadata |
| [login](#heading--login): log user into the store | [logout](#heading--logout): logout user from the store |
| [logs](#heading--logs): retrieve log contents | [model](#heading--model): retrieve and modify model and serial assertions |
| [notices](#heading--notices): retrieve recorded notices | [quotas](#heading--quotas): list and manage quota groups |
| [sections](#heading--sections): request store sections | [snapctl](#heading--snapctl): run the snapctl command |
| [snaps](#heading--snaps): list and manage installed snaps | [snapshots](#heading--snapshots): manipulate, import and export snapshots |
| [systems](#heading--systems-get): list and activate recovery systems | [system-info](#heading--system-info): return host configuration |
| [system-recovery-keys](#heading--system-recovery-keys): view and reset encryption keys | [validation-sets](#heading--validation-sets): list and manage validation-sets |
| [warnings](#heading--warnings): returns snapd warnings | [users](#heading--users): create, remove and query accounts |

---

## GET /

Reserved for human-readable content describing the service.

---

## GET /v2/aliases

* Description: get the available app aliases
* Access: open
* Operation: sync
* Return: dict containing the aliases for each snap

### Response

Example:
```javascript
{
    "snap":
    {
        "alias1":
        {
            "command": "snap.app",
            "status": "auto",
            "auto": "app"
        },
        "alias2":
        {
            "command": "foo",
            "status": "manual",
            "manual": "app1"
            "manual": "app2"
        }
    }
}
```

The result dict is keyed by snap names. Each snap entry is a dict of aliases keyed by alias name:

```javascript
   "lxd": {
      "lxc": {
        "command": "lxd.lxc",
        "status": "auto",
        "auto": "lxc"
      }
    }
```

### Alias Fields

* `command`: the full command this alias runs
* `status`: alias status, one of `auto`, `manual` or `disabled`
* `auto`: the app the alias is for as assigned by an assertion (optional)
* `manual`: the app the alias is for if `status` is `manual` (optional). Overrides `auto`

## POST /v2/aliases

* Description: modify aliases
* Access: authenticated
* Operation: async
* Return: background operation or standard error

### Request

Example:
```javascript
{
    "action": "alias",
    "snap": "moon-buggy",
    "alias": "foo"
}
```

#### Fields

* `action`: either `alias`, `unalias` or `prefer`
* `snap`: snap name to modify (optional for unalias)
* `app`: app to modify (optional)
* `alias`: alias to modify

---

## GET /v2/apps

* Description: list available apps
* Access: open
* Operation: sync
* Return: list of apps available

### Parameters

#### select

Limit which apps are returned. One of:
* `service`: return only services

#### `names`

Comma separated list of snaps to get apps for.

### Response

Example:
```javascript
[
    {
        "snap": "spotify",
        "name": "spotify",
        "desktop-file": "/path/to/file.desktop",
    },
   {
      "snap": "lxd",
      "name": "daemon",
      "daemon": "simple",
      "enabled": true,
      "activators": [
        {
          "Name": "unix",
          "Type": "socket",
          "Active": true,
          "Enabled": true
        }
      ]
    }
]
```

#### Fields

* `snap`: the snap providing the app (optional)
* `name`: the name of the app
* `desktop-file`: the desktop file for the app (optional)
* `daemon`: the daemon type, if a service (optional)
* `enabled`: true if an enabled service (optional)
* `active`: true if an active service (optional)
* `common-id`: common ID associated with this app (optional)
<!-- TODO: activators, type -->


## POST /v2/apps

* Description: modify attributes of applications
* Access: authenticated
* Operation: async
* Return: background operation or standard error

### Request

Example:
```javascript
{
    "action": "stop",
    "names": ["lxd"]
}
```

#### Fields

* `names`: a list of names of snaps (e.g. `multipass`, meaning "all apps in this snap") or apps (e.g. `multipass.multipassd`) to operate on. Cannot be empty
* `action`: the action to perform. Must be one of `stop`, `start`, or `restart`. As these actions only work for services, the `names` given must resolve to at least one service
* `enable`: a boolean (optional, defaults to `false`), when `action` is `start`, arranges to have the service start at system start
* `disable`: a boolean (optional, defaults to `false`), when `action` is `stop`, arranges to no longer start the service at system start
* `reload`: a boolean (optional, defaults to `false`), when `action` is `restart`, try to reload the service instead of restarting, if it supports it -- otherwise, restart

---

## GET /v2/assertions

* Description: get the list of assertion types
* Access: open
* Operation: sync
* Return: list of assertion types

### Response

Example:
```javascript
 {
    "types": [
      "account",
      "account-key",
      "account-key-request",
      "base-declaration",
      "device-session-request",
      "model",
      "repair",
      "serial",
      "serial-request",
      "snap-build",
      "snap-declaration",
      "snap-developer",
      "snap-revision",
      "store",
      "system-user",
      "validation",
      "validation-set"
    ]
}
```

## GET /v2/assertions[/{assertionType}]

* Description: get all the assertions in the system assertion database of the given type
* Access: open
* Operation: sync
* Return: stream of assertions

The response is a stream of assertions separated by double newlines. The X-Ubuntu-Assertions-Count header is set to the number of returned assertions, 0 or more.
Assertions can be filtered on header values using parameters, e.g. `GET /v2/assertions/account?username=canonical` will return all account assertions where `type=account` and `username=canonical`.

Example:
```javascript
type: account
authority-id: canonical
account-id: canonical
display-name: canonical
timestamp: 2016-04-01T00:00:00.0Z
username: canonical
validation: certified
sign-key-sha3-384: <key>

<signature>
```

Note, to determine the boundary between assertions, the headers need to be decoded to check if each assertion contains a body.

### Retrieve a snap-declaration assertion

An assertion type of `snap-declaration` can also be used to retrieve a remote snap-declaration assertion for a given snap-id. This can also be accomplished from within the snap environment:


```bash
$SNAP/usr/bin/curl -sS -X GET --unix-socket /run/snapd.socket "http://localhost/v2/assertions/snap-declaration?series=16&remote=true&snap-id=OHILDGdP7v0yZmkQnvGyXnGD5t2mZZ1g"
```

The above command generates output similar to the following:

```yaml
type: snap-declaration
authority-id: canonical
revision: 4
series: 16
snap-id: oHILDGdP7v0yZmkQnvGyXnGD5t2mZZ1g
publisher-id: oXBKQ6XsXgTcTNVFH6NlFsTz7Epn2kvJ
snap-name: learnit
timestamp: 2016-09-05T18:41:31.767674Z
sign-key-sha3-384: bWDEoaqyr25nF5SNCvEv2v7QnM9QsfCc0PBMYD_i2NGSQ32EF2d4D0hqUel3m8ul

AcLBUgQAAQoABgUCV828WwAAI8YQAEsXwJUhIn4UGCZUQd99vcM8AYVi/Kjyh46ExiYfE198fgPG
5dmWYixeX5PeYSvfhjUF8dVc4l75nMM1nMh9USwnBOJghhl3bfJNOpmaZwW7e5/PS1Ejxjq7kl4p
9uN8h47Gk4p7wjQFu9kAow1d91hyWdwHAxbPbzW9T1X2NmUt2Wh5luFAk6RPW9GBG77ph7pREa51
WiMgK+J85/q8/s9xtjZNbl8vF+F9XY4IsR2IoudQBJSbi7xFQozUcKIuzLlDf/K7U6lgqZPQrgJE
1iMMzTU3PdtCEpEbpbPMlBOC3bXZ0Au2vWyYBebHH25IKmJT3M8E3czf/zyRQJWgE5U8ccRUM3FJ
7R2qqHsiIX8BrDe3Tj+Y72N+WdvZeLjz0M4loNk9r0yl/fLQWGRaj8LJFJk+S7J/u+wwlQblhskx
iPiStUuJSXl5hdJ8NI34i9RbpFcH4cXmJ79IYhcOe29ElxkCeytIthQBgJaFML8H33T0PVxmLn+p
tZp8IKnacrqXBxS/Eh5ToYEW5wuaNqynhalNlZD4ENSlKIV02P/WcPOgle1KIvtQfmYBsbPU4Elk
20H8FPpvBoOS8h5+m1oWPUdqwztXGK70fMqlYMtmY4qUhVRLkwg26BzlIW2VG0ZYAmyMDuWv1fq7
OHKHmYlGG/OLKomKGtqTWuVWqsGG
```

## POST /v2/assertions

* Description: tries to add an assertion to the system assertion database
* Access: authenticated
* Operation: sync
* Return: 200 OK or an error

The body of the request provides the assertion to add. The assertion may also be a newer revision of a pre-existing assertion that it will replace.

To succeed the assertion must be valid, its signature verified with a known public key and the assertion consistent with and its prerequisite in the database.

Example:
```
POST /v2/assertions HTTP/1.1
Content-Type: application/x.ubuntu.assertion
<http-headers>

type: <type>
<assertion-headers>
sign-key-sha3-384: <key>

<signature>
```

---

## GET /v2/changes

* Description: get all the changes in progress
* Access: authenticated
* Operation: sync
* Return: current changes or standard error

Returns an array containing all the changes that have occurred. Changes are returned in the same form as `GET /v2/changes/[id]`.

### Parameters

#### `select`

Limit which changes are returned. One of:
* `all`: all changes returned
* `in-progress`: only changes that are in progress are returned (default)
* `ready`: only changes that are ready

#### `for`

Optional snap name to limit results to.

## GET /v2/changes/[{id}]

* Description: get the current status of a change
* Access: authenticated
* Operation: sync
* Return: current status of change or standard error

### Response

[details=Example auto-refresh change API output]
```javascript
{
  "type": "sync",
  "status-code": 200,
  "status": "OK",
  "result": {
    "id": "4",
    "kind": "auto-refresh",
    "summary": "Auto-refresh snap \"gnome-42-2204\"",
    "status": "Done",
    "tasks": [
      {
        "id": "243",
        "kind": "prerequisites",
        "summary": "Ensure prerequisites for \"gnome-42-2204\" are available",
        "status": "Done",
        "progress": {
          "label": "",
          "done": 1,
          "total": 1
        },
        "spawn-time": "2024-03-28T13:00:35.505604296Z",
        "ready-time": "2024-03-28T13:00:35.547274976Z",
        "data": {
          "affected-snaps": [
            "gnome-42-2204"
          ]
        }
      },
      {
        "id": "244",
        "kind": "download-snap",
        "summary": "Download snap \"gnome-42-2204\" (172) from channel \"latest/stable/ubuntu-24.04\"",
        "status": "Done",
        "progress": {
          "label": "gnome-42-2204 (delta)",
          "done": 100883026,
          "total": 100883026
        },
        "spawn-time": "2024-03-28T13:00:35.505730156Z",
        "ready-time": "2024-03-28T13:01:17.079665072Z",
        "data": {
          "affected-snaps": [
            "gnome-42-2204"
          ]
        }
      },
      {
        "id": "245",
        "kind": "validate-snap",
        "summary": "Fetch and check assertions for snap \"gnome-42-2204\" (172)",
        "status": "Done",
        "progress": {
          "label": "",
          "done": 1,
          "total": 1
        },
        "spawn-time": "2024-03-28T13:00:35.505753989Z",
        "ready-time": "2024-03-28T13:01:19.046188464Z",
        "data": {
          "affected-snaps": [
            "gnome-42-2204"
          ]
        }
      },
      {
        "id": "246",
        "kind": "mount-snap",
        "summary": "Mount snap \"gnome-42-2204\" (172)",
        "status": "Done",
        "progress": {
          "label": "",
          "done": 1,
          "total": 1
        },
        "spawn-time": "2024-03-28T13:00:35.505756356Z",
        "ready-time": "2024-03-28T13:01:19.843614772Z",
        "data": {
          "affected-snaps": [
            "gnome-42-2204"
          ]
        }
      },
      {
        "id": "247",
        "kind": "run-hook",
        "summary": "Run pre-refresh hook of \"gnome-42-2204\" snap if present",
        "status": "Done",
        "progress": {
          "label": "",
          "done": 1,
          "total": 1
        },
        "spawn-time": "2024-03-28T13:00:35.505758703Z",
        "ready-time": "2024-03-28T13:01:19.90621369Z",
        "data": {
          "affected-snaps": [
            "gnome-42-2204"
          ]
        }
      },
      {
        "id": "248",
        "kind": "stop-snap-services",
        "summary": "Stop snap \"gnome-42-2204\" services",
        "status": "Done",
        "progress": {
          "label": "",
          "done": 1,
          "total": 1
        },
        "spawn-time": "2024-03-28T13:00:35.505774942Z",
        "ready-time": "2024-03-28T13:01:19.934043099Z",
        "data": {
          "affected-snaps": [
            "gnome-42-2204"
          ]
        }
      },
      {
        "id": "249",
        "kind": "remove-aliases",
        "summary": "Remove aliases for snap \"gnome-42-2204\"",
        "status": "Done",
        "progress": {
          "label": "",
          "done": 1,
          "total": 1
        },
        "spawn-time": "2024-03-28T13:00:35.505777722Z",
        "ready-time": "2024-03-28T13:01:19.973674463Z",
        "data": {
          "affected-snaps": [
            "gnome-42-2204"
          ]
        }
      },
      {
        "id": "250",
        "kind": "unlink-current-snap",
        "summary": "Make current revision for snap \"gnome-42-2204\" unavailable",
        "status": "Done",
        "progress": {
          "label": "",
          "done": 1,
          "total": 1
        },
        "spawn-time": "2024-03-28T13:00:35.505779025Z",
        "ready-time": "2024-03-28T13:01:20.041785353Z",
        "data": {
          "affected-snaps": [
            "gnome-42-2204"
          ]
        }
      },
      {
        "id": "251",
        "kind": "copy-snap-data",
        "summary": "Copy snap \"gnome-42-2204\" data",
        "status": "Done",
        "progress": {
          "label": "",
          "done": 1,
          "total": 1
        },
        "spawn-time": "2024-03-28T13:00:35.505907022Z",
        "ready-time": "2024-03-28T13:01:20.582550884Z",
        "data": {
          "affected-snaps": [
            "gnome-42-2204"
          ]
        }
      },
      {
        "id": "252",
        "kind": "setup-profiles",
        "summary": "Setup snap \"gnome-42-2204\" (172) security profiles",
        "status": "Done",
        "progress": {
          "label": "",
          "done": 1,
          "total": 1
        },
        "spawn-time": "2024-03-28T13:00:35.505909562Z",
        "ready-time": "2024-03-28T13:01:23.314143988Z",
        "data": {
          "affected-snaps": [
            "gnome-42-2204"
          ]
        }
      },
      {
        "id": "253",
        "kind": "link-snap",
        "summary": "Make snap \"gnome-42-2204\" (172) available to the system",
        "status": "Done",
        "progress": {
          "label": "",
          "done": 1,
          "total": 1
        },
        "spawn-time": "2024-03-28T13:00:35.505910917Z",
        "ready-time": "2024-03-28T13:01:23.48147518Z",
        "data": {
          "affected-snaps": [
            "gnome-42-2204"
          ]
        }
      },
      {
        "id": "254",
        "kind": "auto-connect",
        "summary": "Automatically connect eligible plugs and slots of snap \"gnome-42-2204\"",
        "status": "Done",
        "progress": {
          "label": "",
          "done": 1,
          "total": 1
        },
        "spawn-time": "2024-03-28T13:00:35.505912243Z",
        "ready-time": "2024-03-28T13:01:23.499894041Z",
        "data": {
          "affected-snaps": [
            "gnome-42-2204"
          ]
        }
      },
      {
        "id": "255",
        "kind": "set-auto-aliases",
        "summary": "Set automatic aliases for snap \"gnome-42-2204\"",
        "status": "Done",
        "progress": {
          "label": "",
          "done": 1,
          "total": 1
        },
        "spawn-time": "2024-03-28T13:00:35.505913865Z",
        "ready-time": "2024-03-28T13:01:23.529536457Z",
        "data": {
          "affected-snaps": [
            "gnome-42-2204"
          ]
        }
      },
      {
        "id": "256",
        "kind": "setup-aliases",
        "summary": "Setup snap \"gnome-42-2204\" aliases",
        "status": "Done",
        "progress": {
          "label": "",
          "done": 1,
          "total": 1
        },
        "spawn-time": "2024-03-28T13:00:35.505915366Z",
        "ready-time": "2024-03-28T13:01:23.553118639Z",
        "data": {
          "affected-snaps": [
            "gnome-42-2204"
          ]
        }
      },
      {
        "id": "257",
        "kind": "run-hook",
        "summary": "Run post-refresh hook of \"gnome-42-2204\" snap if present",
        "status": "Done",
        "progress": {
          "label": "",
          "done": 1,
          "total": 1
        },
        "spawn-time": "2024-03-28T13:00:35.505916853Z",
        "ready-time": "2024-03-28T13:01:23.56744097Z",
        "data": {
          "affected-snaps": [
            "gnome-42-2204"
          ]
        }
      },
      {
        "id": "258",
        "kind": "start-snap-services",
        "summary": "Start snap \"gnome-42-2204\" (172) services",
        "status": "Done",
        "progress": {
          "label": "",
          "done": 1,
          "total": 1
        },
        "spawn-time": "2024-03-28T13:00:35.505920905Z",
        "ready-time": "2024-03-28T13:01:23.602721278Z",
        "data": {
          "affected-snaps": [
            "gnome-42-2204"
          ]
        }
      },
      {
        "id": "259",
        "kind": "cleanup",
        "summary": "Clean up \"gnome-42-2204\" (172) install",
        "status": "Done",
        "progress": {
          "label": "",
          "done": 1,
          "total": 1
        },
        "spawn-time": "2024-03-28T13:00:35.505949657Z",
        "ready-time": "2024-03-28T13:01:23.624068681Z",
        "data": {
          "affected-snaps": [
            "gnome-42-2204"
          ]
        }
      },
      {
        "id": "260",
        "kind": "run-hook",
        "summary": "Run configure hook of \"gnome-42-2204\" snap if present",
        "status": "Done",
        "progress": {
          "label": "",
          "done": 1,
          "total": 1
        },
        "spawn-time": "2024-03-28T13:00:35.505954358Z",
        "ready-time": "2024-03-28T13:01:23.647486658Z",
        "data": {
          "affected-snaps": [
            "gnome-42-2204"
          ]
        }
      },
      {
        "id": "261",
        "kind": "run-hook",
        "summary": "Run health check of \"gnome-42-2204\" snap",
        "status": "Done",
        "progress": {
          "label": "",
          "done": 1,
          "total": 1
        },
        "spawn-time": "2024-03-28T13:00:35.50596174Z",
        "ready-time": "2024-03-28T13:01:23.673947264Z",
        "data": {
          "affected-snaps": [
            "gnome-42-2204"
          ]
        }
      },
      {
        "id": "262",
        "kind": "check-rerefresh",
        "summary": "Monitoring snap \"gnome-42-2204\" to determine whether extra refresh steps are required",
        "status": "Done",
        "log": [
          "2024-03-28T13:01:25Z INFO No re-refreshes found."
        ],
        "progress": {
          "label": "",
          "done": 1,
          "total": 1
        },
        "spawn-time": "2024-03-28T13:00:35.506102824Z",
        "ready-time": "2024-03-28T13:01:25.812673268Z"
      }
    ],
    "ready": true,
    "spawn-time": "2024-03-28T13:00:35.506186473Z",
    "ready-time": "2024-03-28T13:01:25.812676746Z",
    "data": {
      "snap-names": [
        "gnome-42-2204"
      ]
    }
  }
}
```

[/details]

#### Fields

* `id`: a unique ID for this change
* `kind`: a code describing what type of change this is
* `summary`: human readable description of the change
* `status`: summary status of the current combined task statuses (see below)
* `tasks`: array of objects describing tasks in this change (optional, see below)
* `ready`: true if this change has completed
* `spawn-time`: the time this change started in in RFC3339 UTC format with µs precision
* `ready-time`: the time this change completed in RFC3339 UTC format with µs precision. (omitted if not completed)
* `err`: human readable error description if transaction has failed (optional, omitted until completed)
* `data`: result of the change

#### Data fields according to kind
##### auto-refresh:

* `refresh-forced`: a list of snaps whose refresh was previously inhibited and were force-continued in this auto-refresh change due to a maximum inhibition timeout (optional)

Example:
```javascript
{
    "kind": "auto-refresh"
    "data": {
        "snap-names": ["instance-name"],
        "refresh-forced": ["instance-name"]
    }
}
```

The `snap-names` data field is attached to all changes related to snap operations and shows the list of affected snaps.

#### Task Fields

* `id`: a unique ID for this task
* `kind`: a code describing what type of task this is
* `summary`: human readable description of the task
* `status`: one of the following status codes:
  * `"Abort"` - Task has been aborted.
  * `"Do"` - Task ready to start.
  * `"Doing"` - Task in progress.
  * `"Done"` - Task is complete.
  * `"Error"` - Task completed with an error.
  * `"Hold"` - Task will not be run (probably due to failure of another task).
  * `"Undo"` - Task needs to be undone.
  * `"Undoing"` - Task is being undone.
  * `"Wait"` - Task was successful but an external event needs to occur before work can progress further. One example is requiring a reboot after a kernel snap update on classic Ubuntu systems.
* `progress`: object containing the current progress of this task. `label` is a human readable description of the progress, `done` and `total` are numbers showing the progress of this task
* `spawn-time`: the time this task was created in RFC3339 UTC format with µs precision
* `ready-time`: the time this task completed in RFC3339 UTC format with µs precision (omitted if not completed)
* `data`: result of the task (optional)
  * `affected-snaps`: array of strings describing snaps affected by task

## POST /v2/changes/[id]

* Description: abort a change in progress
* Access: authenticated
* Operation: sync
* Return: current status of change or standard error

### Request

Example:
```javascript
{
    "action": "abort"
}
```

### Response

See return from GET.

---

## POST /v2/cohorts

* Description: create creates a set of cohort keys for a given set of snaps
* Access: authenticated
* Operation: sync
* Return: cohorts key or standard error

### Fields

* `action`: `create`
* `snaps`: array of snap names to be included in the cohort

---

## GET /v2/connections

* Description: get all the interface connections
* Access: open
* Operation: sync
* Return: connection status of plugs and slots

### Parameters

#### `snap`

Limit results to a given snap name.

#### `select`

When set to `all`, unconnected slots and plugs are included in the results. When unset or empty, the results include only those plugs and slots that are connected.

#### `interface`

Takes an interface name. When set, the results are limited to the selected interface.

### Example

```javascript
{
    "established": [
        {
            "slot": { "snap": "core", "slot": "home" },
            "plug": { "snap": "foo", "plug": "home" },
            "interface": "home",
        },
        {
            "slot": { "snap": "core", "slot": "network-control" },
            "plug": { "snap": "foo", "plug": "network-control" },
            "interface": "network-control",
            "manual": true
        }
    ],
    "undesired": [
        {
            "slot": { "snap": "core", "slot": "foo-data" },
            "plug": { "snap": "foo", "plug": "foo-data" },
            "interface": "content",
            "manual": true
        }
    ],
    "plugs": [
        {
            "snap": "foo",
            "slot": "home",
            "interface": "home",
            "connections": [
                { "snap": "core", "slot": "home" }
            ]
        },
        {
            "snap": "foo",
            "slot": "network-control",
            "interface": "network-control",
            "connections": [
                { "snap": "core", "slot": "network-control" }
            ]
        }
    ],
    "slots": [
        {
            "snap": "core",
            "slot": "home",
            "interface": "home",
            "connections": [
                { "snap": "foo", "plug": "home" }
            ]
        },
        {
            "snap": "core",
            "slot": "network-control",
            "interface": "network-control",
            "connections": [
                { "snap": "foo", "plug": "network-control" }
            ]
        }
    ]
}
```

#### Fields

* `established`: array of connections made with slots and plugs
* `undesired`: array of connections that have been manually disconnected. These connections would otherwise be automatically made
* `plugs`: array of connected plugs
* `slots`: array of connected slots

#### Fields for plugs / slots

* `snap`: the snap this plug / slot is part of
* `plug` or `slot`: the name of this plug / slot
* `interface`: the interface this plug / slot uses
* `attrs`: dict containing attributes for the interface in use. Attributes values can be of any type, e.g. boolean, strings etc
* `label`: human readable description of plug / slot
* `connections`: list of current slots / plugs that are connected to this. Each connection contains the name of the snap and the connected slot / plug

#### Connection fields

* `slot`: snap and slot name connected
* `plug`: plug and slot name connected
* `interface`: name of interface in use
* `manual`: set to `true` if this interface was manually connected by a user
* `gadget`: set to `true` if this interface was connected by the gadget snap
* `slot-attrs`: object of slot attributes for this connection
* `plug-attrs`: object of plug attributes for this connection

---

## GET /v2/find

* Description: find snaps in the store
* Access: open or authenticated
* Operation: sync
* Return: list of snaps in the store that match the search term and that the host system can handle

### Parameters

#### `name`

Search for snaps whose name matches the given string. Can’t be used together with  `q` . This is meant for things like autocompletion. The match is exact (i.e. find would return 0 or 1 results) unless the string ends in  `*` .

#### `q`

Search for snaps that match the given string. Spaces between words are treated as logical AND operators. This is a weighted broad search, meant as the main interface to searching for snaps.

#### `scope`

If set to `wide`, the search results are broadened to include non-stable packages.

#### `section`

Section in the store to search. Use `GET /v2/sections` to get the names of the sections.

#### `select`

Alter the collection searched:

* `refresh`: search refreshable snaps. Can't be used with `q`, nor `name`
* `private`: search private snaps (by default, find only searches public snaps). Can't be used with `name`, only `q` (for now at least).

#### `common-id`

Search for snaps using the common-id snap app attribute. This is often the application name used by other packaging formats, such as `org.videolan.vlc` for the VLC media player.

### Example

#### Request

```bash
http://localhost/v2/find\?q\=libreoffice | jq
```

#### Response

```javascript
[
    {
      "id": "CpUkI0qPIIBVRsjy49adNq4D6Ra72y4v",
      "title": "LibreOffice",
      "summary": "LibreOffice is a powerful office suite including word processing and creation of spreadsheets, slideshows and databases",
      "description": "LibreOffice is a powerful and free office suite, used by millions of people around the world. Its clean interface and feature-rich tools help you unleash your creativity and enhance your productivity. LibreOffice includes several applications that make it the most versatile Free and Open Source office suite on the market: writer (word processing), Calc (spreadsheets), Impress (presentations), Draw (vector graphics and flowcharts), Base (databases), and Math (formula editing).",
      "download-size": 436375552,
      "icon": "https://dashboard.snapcraft.io/site_media/appmedia/2016/06/LibreOffice-Initial-Artwork-Logo.png",
      "name": "libreoffice",
      "publisher": {
        "id": "canonical",
        "username": "canonical",
        "display-name": "Canonical",
        "validation": "verified"
      },
      "store-url": "https://snapcraft.io/libreoffice",
      "developer": "canonical",
      "status": "available",
      "type": "app",
      "base": "core18",
      "version": "6.4.4.2",
      "channel": "stable",
      "ignore-validation": false,
      "revision": "180",
      "confinement": "strict",
      "private": false,
      "devmode": false,
      "jailmode": false,
      "contact": "https://bugs.launchpad.net/ubuntu/+source/libreoffice/+bugs?field.tag=snap",
      "license": "MPL-2.0",
      "common-ids": [
        "libreoffice-draw.desktop",
        "libreoffice-impress.desktop",
        "libreoffice-writer.desktop",
        "libreoffice-math.desktop",
        "libreoffice-calc.desktop",
        "libreoffice-base.desktop"
      ],
      "website": "https://code.launchpad.net/~libreoffice/+git/libreoffice-snap",
      "media": [
        {
          "type": "icon",
          "url": "https://dashboard.snapcraft.io/site_media/appmedia/2016/06/LibreOffice-Initial-Artwork-Logo.png"
        },
        {
          "type": "banner",
          "url": "https://dashboard.snapcraft.io/site_media/appmedia/2019/12/LibreOffice-Banner_1IRAqHI.png",
          "width": 2100,
          "height": 700
        },
        {
          "type": "screenshot",
          "url": "https://dashboard.snapcraft.io/site_media/appmedia/2019/09/Screenshot-01-New-EN.png",
          "width": 1082,
          "height": 651
        },
        {
          "type": "screenshot",
          "url": "https://dashboard.snapcraft.io/site_media/appmedia/2019/09/Screenshot-04-New-EN.png",
          "width": 1080,
          "height": 648
        },
        {
          "type": "screenshot",
          "url": "https://dashboard.snapcraft.io/site_media/appmedia/2019/09/Screenshot-05-New-EN.png",
          "width": 1080,
          "height": 647
        },
        {
          "type": "screenshot",
          "url": "https://dashboard.snapcraft.io/site_media/appmedia/2019/09/Screenshot-06-New-EN.png",
          "width": 1080,
          "height": 647
        },
        {
          "type": "screenshot",
          "url": "https://dashboard.snapcraft.io/site_media/appmedia/2019/09/Screenshot-07-New-EN.png",
          "width": 1081,
          "height": 647
        }
      ],
      "install-date": "2020-06-02T17:25:50.864197657+01:00"
    }
]
```

#### Fields

* `base`: the base snap this snap relies on (optional)
* `channel`: the channel this snap is from
* `channels`: available channels to download. See below for fields. (only returned for searches with name parameter)
* `common-ids`: common IDs used by the apps in this snap
* `confinement`: the confinement requested by the snap itself; one of `strict`, `classic` or `devmode`
* `contact`: the method of contacting the developer
* `description`: snap description
* `developer`: developer who created the snap (deprecated, use `username` from `publisher` instead)
* `download-size`: how big the download will be in bytes
* `epoch`: the epoch of the application release. See [Snap epochs](/t/snap-epochs/10316) for details
* `icon`: a url to the snap icon, possibly relative to this server
* `id`: unique ID for this snap
* `license`: an [SPDX](https://spdx.org/licenses/) license expression
* `name`: the snap name
* `private`: true if this snap is only available to its author
* `publisher`: publisher information, made up of an `id`, `username` and `display-name`
* `released-at`: date when app was released
* `resource`: hTTP resource for this snap
* `revision`: a number representing the revision, as a base 10 string
* `media`: jSON array of  media for this snap with each element consisting of a `type` , `url` and potentially a `width` and `height` for image media
   ```javascript
        {
          "type": "icon",
          "url": "https://dashboard.snapcraft.io/site_media/appmedia/2016/06/LibreOffice-Initial-Artwork-Logo.png"
        },
        {
          "type": "banner",
          "url": "https://dashboard.snapcraft.io/site_media/appmedia/2019/12/LibreOffice-Banner_1IRAqHI.png",
          "width": 2100,
          "height": 700
        }
    ```

#### Channel Fields

* `channel`: the channel this snap is from
* `confinement`: the confinement requested by the snap itself; one of `strict`, `classic` or `devmode`
* `epoch`: ?. Must be in the form of an integer
* `released-at`: date this revision was released into the channel in RFC3339 UTC format
* `revision`: a number representing the revision in this channel, as a base 10 string
* `size`: how big the download will be in bytes
* `version`: a string representing the version in this channel

---

## GET /v2/icons/{name}/icon

* Description: get an icon from a snap installed on the system.
* Access: open

This is *not* a standard return type. The response will be the raw contents of the icon file; the content-type will be set accordingly and the Content-Disposition header will specify the filename.

This fetches the icon from the snap itself.

<!-- XXX explain difference between "/v2/interfaces" and "/v2/connections" -->

---

## GET /v2/interfaces

* Description: get the available interfaces and associated metadata
* Access: authenticated
* Operation: sync
* Return: an array of interface information

### Parameters

#### `select`

Set to `all` to retrieve all interfaces, or `connected` to only return connected interfaces (if this parameter is omitted then the call returns the legacy format that should be no longer used).

#### slots

If `true`, then slot information is returned.

#### plugs

If `true`, then plug information is returned.

#### doc

If `true` then interface documentation is returned.

#### names

If given, then only interfaces that match the comma separated names are returned.

Example:
```javascript
[
    {
        "name": "content",
        "summary": "allows sharing code and data with other snaps"
        "plugs": [
            { "snap": "foo", "plug": "foo-data" }
        ]
    },
    {
        "name": "home",
        "summary": "allows access to non-hidden files in the home directory",
        "plugs": [
            { "snap": "foo", "plug": "home" }
        ]
    },
    {
        "name": "network-control",
        "summary": "allows configuring networking and network namespaces"
        "plugs": [
            { "snap": "foo", "plug": "network-control" }
        ]
    }
]
```

#### Fields

* `name`: name of interface
* `summary`: human-readable summary of interface (optional)
* `doc-url`: uRL to further documentation (optional)
* `plugs`: plugs using this interface (only if using `plugs=true`)
* `slots`: plugs using this interface (only if using `slots=true`)

## POST /v2/interfaces

* Description: issue an action to the interface system
* Access: authenticated
* Operation: async
* Return: background operation or standard error

Example:
```javascript
{
    "action": "connect",
    "slots": [{"snap": "canonical-pi2",   "slot": "pin-13"}],
    "plugs": [{"snap": "keyboard-lights", "plug": "capslock-led"}]
}
```

#### Fields

* `action`: action to perform, either `"connect"` or `"disconnect"`
* `plugs`: array of plugs to connect. Each plug is referred to by the `snap` it is part of and the name of the `plug`
* `slots`: array of slots to connect to. Each slot is referred to by the `snap` it is part of and the name of the `slot`

---

## POST /v2/login

* Description: log user in the store
* Access: root
* Operation: sync
* Return: dict with the authenticated user information or error

### Request

Example:
```javascript
{
     "email": "foo@bar.com",
     "password": "swordfish",
     "otp": "123456"
}
```

#### Fields

* `email`: the email address being logged in with. This must be a valid email address (also supported with legacy `username` field)
* `password`: password for this account
* `otp`: one time password for this account (optional). This field being wrong will generate the `two-factor-required` or `two-factor-failed` errors

### Response

Example:
```javascript
{
    "id": 1,
    "username": "user1",
    "email": "user1@example.com",
    "macaroon": "serialized-store-macaroon",
    "discharges": ["discharge-for-macaroon-authentication"]
}
```

#### Fields

* `id`: unique ID for this user account
* `email`: email address associated with this account
* `username`: local username associated with this account (optional)
* `macaroon`: serialized macaroon to be passed back in the HTTP `Authorization` header
* `discharges`: array of serialized discharges to be passed back in the HTTP `Authorization` header

---

## POST /v2/logout

* Description: log user out of the store
* Access: authenticated
* Operation: sync
* Return: 200 OK or an error

---

## GET /v2/logs

* Description: get log contents
* Access: open
* Operation: sync
* Return: a sequence of log messages

### Parameters

#### `n`

Number of entries to return or `all` for all entries. Defaults to 10 entries.

#### `follow`

If set then returns log entries as they occur.

### Response

Example:
```
HTTP/1.1 200 OK
Content-Type: application/json-seq
<http-headers>

<0x1E>{"timestamp":"2017-11-06T02:13:29.707407Z","message":"Thing occurred","sid":"service1","pid":"1000"}
<0x1E>{"timestamp":"2017-11-06T02:13:29.708319Z","message":"Other thing occurred","sid":"service1","pid":"1000"}
```

---

## GET /v2/model

* Description: retrieve the active [model assertion](https://ubuntu.com/core/docs/reference/assertions/model) for the system
* Access: open
* Operation: sync
* Return: the model assertion for the device or system

#### Response

Example:

```yaml
type: model
authority-id: generic
series: 16
brand-id: generic
model: generic-classic
classic: true
timestamp: 2017-07-27T00:00:00.0Z
sign-key-sha3-384: d-JcZF9nD9eBw7bwMnH61x-bklnQOhQud1Is6o_cn2wTj8EYDi9musrIT9z2MdAa

AcLBXAQAAQ[...]
```

## GET /v2/model/serial

* Description: retrieve the current [serial assertion](https://ubuntu.com/core/docs/reference/assertions/serial) for the system
* Access: open
* Operation: sync
* Return: the serial assertion for the device or system

#### Response

Example:

```yaml
type: serial
authority-id: generic
brand-id: generic
model: generic-classic
serial: 46923e6d-5d45-420d-905a-99a9e92493b4
device-key:
    [...]
device-key-sha3-384: 856SE5VcaoS0T8ccMMb22xtuqLLXTxyrBGoFYfG-vXMyx5urvl4i4s2-ZxH_WovR
timestamp: 2017-10-11T08:11:22.422257Z
sign-key-sha3-384: wrfougkz3Huq2T_KklfnufCC0HzG7bJ9wP99GV0FF-D3QH3eJtuSRlQc2JhrAoh1
[...]
```

## POST /v2/model

- Description: replace the current model assertion
- Access: authenticated
- Operation: async
- Return: 202 OK or an error

Can be either:
- JSON content-type, containing only the model assertion and requiring online store access to retrieve other components
- multipart/form-data content-type, to side-load whatever new components may be required. See [offline remodelling](https://ubuntu.com/core/docs/remodelling#heading--offline).

## POST /v2/model/serial

- Description: replace the active serial assertion
- Access: authenticated
- Operation: async
- Return: 202 OK or an error

---

## GET /v2/notices

* Description: retrieve notices for the current user and any public notices
* Access: open
* Operation: sync
* Return: the details of any recorded notice which matches the given filters

### Parameters

The following parameters filter the notices returned by the API call. Notices must match every provided filter to be included.

#### `types`

If `types` is specified, only return notices with types matching the given types. Types may be any of:
* `change-update`: recorded when a change is spawned or whenever its status is updated. The `key` is the change ID.
* `warning`: a warning created by snapd. The `key` is a human-readable warning message.
* `refresh-inhibit`: recorded when an auto-refresh is inhibited for one or more snaps. The `key` is always `-`.

The `types` parameter can be included multiple types, and notices matching any of the types are returned.

#### `keys`

If `keys` is specified, only return notices with one of the given keys.

#### `after`

If `after` is specified, only return notices with a `LastRepeated` field greater than the specified time, which should be in RFC3339 format.

#### `timeout`

If there are notices matching the filter which have already been recorded, these notices are returned immediately. Otherwise, if `timeout` is specified, wait up to the given duration for any new notices matching the filter to be recorded. This allows the user to use long-polling to be notified immediately when a new notice is recorded.

#### `user-id`

Admin only.

Instead of returning notices associated with the user who initiated the API request, return notices associated with the given UID. Public notices are still returned, as before.

Cannot be used with the `users` parameter.

#### `users`

Admin only.

Value must be `all`. Return notices associated with all users, instead of just the user which initiated the API request.

Cannot be used with the `user-id` parameter.

### Response

Example:

```json
{
  "type": "sync",
  "status-code": 200,
  "status": "OK",
  "result": [
    {
      "id": "1",
      "user-id": null,
      "type": "change-update",
      "key": "5",
      "first-occurred": "2024-03-28T19:24:31.224894652Z",
      "last-occurred": "2024-03-28T19:24:31.97763631Z",
      "last-repeated": "2024-03-28T19:24:31.97763631Z",
      "occurrences": 2,
      "last-data": {
        "kind": "refresh-snap"
      },
      "expire-after": "168h0m0s"
    }
  ]
}
```

#### Fields

- `id`: the unique ID of the given notice
- `user-id`: the UID of the user who may view the notice (often its creator), or `null` if the notice is public (viewable by all users)
- `type`: the type of the notice, which may be one of the following:
  - `change-update`: recorded when a _change_ is spawned or whenever its status is updated
  - `warning`: a warning created by snapd
  - `refresh-inhibit`: recorded when an auto-refresh is inhibited for one or more snaps
- `key`: an identifier which is type-specific and unique among notices for a particular user and type
  - For `change-update` notices, the key is the change ID
  - For `warning` notices, the key is a human-readable warning message
  - For `refresh-inhibit` notices, the key is always `-`
- `first-occurred`: the timestamp of the first time one of these notices (user ID, type, and key combination) occurred, in RFC3339 format
- `last-occurred`: the timestamp of the last time one of these notices occurred, in RFC3339 format, which is updated every time one of these notices occurs.
- `last-repeated`: the timestamp of the last time one of these notices repeated, in RFC3339 format, which is set when one of these notices first occurs and updated when it reoccurs at least `repeat-after` after the previous `last-repeated` time.
- `occurrences`: the number of times one of these notices has been recorded
- `last-data`: additional data captured from the last occurrence of one of these notices
- `repeat-after`: the duration after one of these notices was last repeated before it is allowed to repeat again
- `expire-after`: the duration after one of these notices was last recorded before it should be dropped

---

## GET /v2/quotas

* Description: get all [Quota groups](/t/quota-groups/25553)
* Access: open
* Operation: sync
* Return: a list of quota groups and the constraints they contain

#### Response

Example:

```json
{
  "group-name": "highmem",
  "subgroups": [
    "lowmem"
  ],
  "snaps": [
    "test-server"
  ],
  "constraints": {
    "memory": 2000000000
  },
  "current": {}
},
{
  "group-name": "loggroup",
  "snaps": [
    "nextcloud"
  ],
  "constraints": {
    "journal": {
      "size": 64000000
    }
  },
  "current": {}
},
{
  "group-name": "logmem",
  "constraints": {
    "memory": 64000000,
    "journal": {
      "size": 64000000
    }
  },
  "current": {}
},
{
  "group-name": "lowmem",
  "parent": "highmem",
  "constraints": {
    "memory": 1000000000
  },
  "current": {}
}
```

#### Fields

- `group-name`: name of the quota group.
- `subgroups`: lists any subgroups this quota group contains. 
- `parent`: contains the parent quota group name, if this group is a subgroup.
- `snaps`: lists any snaps that belong to this quota group.
- `services`: only for a subgroup, lists specific services belonging to a snap in the parent group.
- `constraints`: types and values of limits defined for this quota group:
  - `memory`: memory usage limit.
  - `cpu`: includes `percentage` as a limit.
  - `cpu-set`: per-cpu limits, with `cpus` listing included cores.
  - `threads`: maximum number of threads for this quota group.
  - `journal`: number of messages logged per time period.
  - `journal`: includes `size` and both `rate-count` and `rate-period` for rate limits.
- `current`: contains the current usage of memory and task quotas,  such as `"memory": 450` to show 450 bytes are currently being used in a group with a memory limit. 

## GET /v2/quotas[/{group-name}]

* Access: open
* Operation: sync
* Return: either a single quota group, or an error

### Response

Example:

```json
{
    "group-name": "allquotas",
    "constraints": {
      "memory": 64000000,
      "cpu": {
        "percentage": 50
      },
      "cpu-set": {
        "cpus": [
          0,
          1
        ]
      },
      "threads": 4096,
      "journal": {
        "size": 32000000,
        "rate-count": 10,
        "rate-period": 3600000000000
      }
    },
    "current": {}
}
```

For a description of the fields returned by this request, see [`GET /v2/quotas`](#heading--quotas-fields) above.

## POST /v2/quotas

- Description: create, modify or remove a quota group
- Access: authenticated
- Operation: async
- Return: 202 OK or an error

### Request

Example:

```json
{
    "action": "ensure",
    "group-name": "quotagroup",
    "parent": "quotaparent",
    "snaps": ["snap1", "snap2"],
    "services": ["snap1.svc1", "snap2.svc"],
    "constraints": [{"journal":{"size":64000000}}]
}
```

#### Fields

- `action`: action to perform. Must be either `ensure` or `remove`:
  - `ensure`: creates or modifies a pre-existing group with the fields supported by quotas. See [`GET /v2/quotas`](#heading--quotas-fields) above.
  - `remove`: removes a quota group. Only `group-name` is required.

---

## GET /v2/sections

* Description: get the store sections
* Access: open
* Operation: sync
* Return: an array containing the store section names

### Response

Example:
```javascript
[
   "featured",
   "database",
   "ops",
   "messaging",
   "media",
   "internet-of-things"
]
```

---

## POST /v2/snapctl

* Description: run snapctl command
* Access: authenticated
* Operation: sync
* Return: command output or standard error

### Request

Example:
```javascript
{
    "context-id": "ABCDEF",
    "args": [ "get", "username" ]
}
```

#### Fields

* `context-id`: context for this call
* `args`: arguments to snapctl

### Response

Example:
```javascript
{
    "stdout": "username",
    "stderr": ""
}
```

#### Fields

* `stdout`: data written to stdout from snapctl command
* `stderr`: data written to stderr from snapctl command

---

## GET /v2/snaps

* Description: list installed snaps
* Access: open
* Operation: sync
* Return: list of snaps installed on the system, as for `/v2/find`

### select

Filter snaps to return information about:

* `all`: show all snap revisions installed
* `enabled`: show only revisions of snaps that are active (default)
* `refresh-inhibited`: shows snaps that are inhibited for refresh.

#### `snaps`

Return only information for the given snaps. Snap names are separated by commas.

### Response

Example:
<!-- XXX: check output for missing new fields -->
```javascript
[{
      "apps": [{"name": "moon-buggy"}]
      "channel": "stable"
      "confinement": "strict"
      "description": "Moon-buggy is a simple character graphics game, where you drive some kind of car across the moon's surface.  Unfortunately there are dangerous craters there.  Fortunately your car can jump over them!\r\n",
      "developer": "dholbach",
      "devmode": false,
      "icon": "",
      "id": "2kkitQurgOkL3foImG4wDwn9CIANuHlt",
      "install-date": "2016-05-17T09:36:53+12:00",
      "installed-size": 90112,
      "license": "GPL-2.0+",
      "name": "moon-buggy",
      "private": false,
      "resource": "/v2/snaps/moon-buggy",
      "revision": "11",
      "status": "active",
      "summary": "Drive a car across the moon",
      "trymode": false,
      "type": "app",
      "version": "1.0.51.11",
      "refresh-inhibit": {"proceed-time": "2024-04-17T12:51:25.742080444+02:00"},
    }, {
      "summary": "The ubuntu-core OS snap",
      "description": "A secure, minimal transactional OS for devices and containers.",
      "icon": "",                  // core might not have an icon
      "installed-size": 67784704,
      "install-date": "2016-03-08T11:29:21Z",
      "name": "core",
      "developer": "canonical",
      "resource": "/v2/snaps/ubuntu-core",
      "status": "active",
      "type": "core",
      "update-available": 247,
      "version": "241",
      "revision": 99,
      "channel": "stable",
}]
```

#### Fields

In addition to the fields described in `/v2/find`:

* `apps`: jSON array of apps the snap provides. See below for fields
* `broken`: a string describing if this snap is not working (optional)
* `devmode`: `true` if the snap is currently installed in development mode
* `installed-size`: how much space the snap itself (not its data) uses
* `install-date`: the date and time when the snap was installed in RFC3339 UTC format
* `jailmode`: `true` if the app is currently installed in jail mode
* `mounted-from`: path the snap is mounted from,  which is a .snap file for installed snaps and a directory for snaps in try mode
* `status`: can be either `installed` or `active` (i.e. is current)
<!-- XXX: explain tracking-channel vs channel -->
* `tracking-channel`: the channel updates will be installed from
* `trymode`: `true` if the app was installed in try mode
* `refresh-inhibit`:  contains `proceed-time` which is the date and time after which a refresh is forced for a running snap in the next auto-refresh in RFC3339 UTC format (optional)

Furthermore, `channels`, `download-size`, `screenshots` and `tracks` cannot occur in the output of `/v2/snaps`.

#### App Fields

* `name`: name of the app, i.e. the name of the executable
* `aliases`: a list of alias names for this app (optional)
* `common-id`: a common ID associated with this app (optional)
* `daemon`: the type of daemon this app is. One of "simple", "forking", "oneshot", "dbus" or "notify" (optional, only applicable for daemons)
* `desktop-file`: path to desktop file for this app (optional)

## POST /v2/snaps

* Description: install, refresh, revert, remove, hold, unhold, enable, disable, switch or snapshot snaps
* Access: authenticated
* Operation: async
* Return: background operation or standard error

### Store Request

Example:
```javascript
{
    "action": "refresh",
    "snaps": ["moon-buggy"]
}
```

#### Fields

* `action`: either `install`, `refresh`, `remove`, `revert`, `hold`, `unhold`, `enable`, `disable` or `switch`
* `snaps`: array of snap names to perform action on (optional, interpreted as all snaps if not present for a refresh)
* `transaction`: optional string field, defaulting to **per-snap** if not present. If **all-snaps** is used, the action field will be performed such that the corresponding change will have a single transaction covering all the snaps. If in this case there is a failure for any snap, the state of all affected snaps will be fully reverted, even if for some snap the action has been successful. This field is valid for _install_ and _refresh_ actions. See [Transactional updates](/t/transactional-updates/29615) for more details
* `system-restart-immediate`: if `true`, makes any system restart, needed by the action, immediate and without delay (requires _snapd 2.52_)
* `validation-sets`: array of validation sets to enforce, refreshing and installing snaps as required. Cannot be used in tandem with the 'snaps' field (optional)

#### Hold only

The `hold` action holds, or postpones, snap updates for individual snaps, or for all snaps on the system, either indefinitely or for a specified period of time. 

Requires snapd 2.58+.

#### Fields

* `hold-level`: `general` or `auto-refresh` to target specific snap refreshes or automatic updates respectively
* `time`: instant until which the refresh is held. Specified either in RFC3339 format or `forever` to postpone updates indefinitely. Time instants are always accepted even if they have already passed

Similar functionality is provided by the [`snap refresh --hold`](/t/managing-updates/7022#heading--hold) command.

#### Sideload Request

Snaps can be sideloaded by passing the snap content in a `multipart/form-data` request with one or more files named "snap".

Example:
```
POST /v2/snaps HTTP/1.1
Host:
Content-Type: multipart/form-data; boundary=foo
Content-Length: 20638

--foo
Content-Disposition: form-data; name="devmode"

true
--foo
Content-Disposition: form-data; name="snap"; filename="hello-world_27.snap"

<20480 bytes of snap file data>
--foo
Content-Disposition: form-data; name="snap"; filename="other-snap_1.snap"

<20480 bytes of snap file data>
--foo
```

The following fields are supported:
* `action`: the action to perform, either `install` or `try` (optional, defaults to `install`)
* `classic`: put snaps in classic mode and disable security confinement if `true` (optional)
* `dangerous`: install the given snap files even if there are no pre-acknowledged signatures for them, meaning they are not verified and could be dangerous if `true` (optional, implied by `devmode`)
* `devmode`: put snaps in development mode and disable security confinement if `true` (optional)
* `jailmode`: put snaps in enforced confinement mode if `true` (optional)
* `system-restart-immediate`: if `true`, makes any system restart, needed by the action, immediate and without delay (requires _snapd 2.52_)
* `snap`: the contents of a snap file. Note that `filename` is required to be set but the value is not used. `Content-Type` is not required, but recommended  (optional, required if `action` is `install`)
* `snap-path`: directory to install in try mode (optional, required if `action` is `try`)

### Snapshot creation

Example:
```json
{
    "action": "snapshot",
    "snaps": ["snap1", "snap2"],
    "users": ["user1", "user1"],
    "snapshot-options":
      { 
        "snap1":
          { 
            "exclude": ["$SNAP_DATA/*.bak","$SNAP_COMMON/cache", "$SNAP_USER_DATA/.gnupg", "$SNAP_USER_COMMON/cache"]
          },
        "snap2":
          {
            "exclude": ["$SNAP_DATA/*.bak", "$SNAP_COMMON/exclude", "$SNAP_USER_DATA/.gnupg", "$SNAP_USER_COMMON/large-files"]
          }
      }
}
```

#### Fields

* `action`: `snapshot`
* `snaps`: array of snap names whose data should be snapshotted
* `users`: array of user names to whom snapshots are to be restricted (optional)
* `snapshot-options`: list of snapshot options per snap that requires dynamic snapshot data exclusion. Snapshot options currently consist of only the "exclude" field that contains a list of wildcard patterns for files or directories to exclude from the snapshot data (optional)

> ⓘ Note that the `snapshot-options` field, which enables dynamic exclusion of snapshot data, is currently an experimental feature

Result:
```json
{
    "result": {"set-id": 42},
    "change": "999",
    "status-code": 202,
    "type": "async"
}
```

---

## GET /v2/snaps/{name}

* Description: details for an installed snap
* Access: open
* Operation: sync
* Return: snap details (as in `/v2/snaps`)

## POST /v2/snaps/{name}

* Description: install, refresh, remove, revert, enable or disable
* Access: authenticated
* Operation: async
* Return: background operation or standard error

### Request

Example:
```javascript
{
    "action": "install",
    "channel": "beta"
}
```

#### Fields

* `action`: either `install`, `refresh`, `remove`, `revert`, `enable`, `disable` or `switch`
* `channel`: from which channel to pull the new package (and track henceforth). Channels are a means to discern the maturity of a package or the software it contains, although the exact meaning is left to the application developer. One of `edge`, `beta`, `candidate`, and `stable` which is the default. (optional, only applicable when `action` is `install` or `refresh`)
* `classic`: put snap in classic mode and disable security confinement if `true` (optional, only applicable with `action` set to `install`, `refresh`, `revert`)
* `devmode`: put snap in development mode and disable security confinement if `true` (optional, only applicable with `action` set to `install`, `refresh`, `revert`)
* `ignore-validation`: ignore validation by other snaps blocking the refresh if `true` (optional, only applicable with `action` set to `refresh`)
* `jailmode`: put snap in enforced confinement mode if `true` (optional, only applicable with `action` set to `install`, `refresh`, `revert`)
* `revision`: revision to install (optional, only applicable with `action` set to `install`, `refresh` or `revert`)
* `purge`: don't save a snapshot with the snap's data when removing if set to `true` (optional, only applicable with `action` set to `remove`)
* `system-restart-immediate`: make any system restart needed by the action immediate without delay if `true` (requires _snapd 2.52_)

## GET /v2/snaps/{name}/conf

* Description: configuration details for an installed snap 
* Access: authenticated
* Operation: sync
* Return: jSON map of configuration keys and values

`name` can be the reserved name `system` to get system options.

### Parameters

#### `keys`

Request the configuration values corresponding to the specific keys (comma-separated); dotted keys can be used to retrieve nested values .

## PUT /v2/snaps/{name}/conf

* Description: set the configuration details for an installed snap 
* Access: authenticated
* Operation: async
* Return: background operation or standard error

 `name` can be the reserved name `system` to set system options.

### Request

Example:
```javascript
{
    "conf-key1": "conf-value1",
    "conf-key2": "conf-value2"
}
```
Keys can be dotted, the `null` value can be used to unset configuration options.

---

## GET /v2/snapshots

* Description: get a list of snapshots
* Access: open
* Operation: sync
* Return: list containing metadata for stored [snapshots](/t/snapshots/9468)

Returns an array containing all the snapshot metadata stored on the system.

### Response

Example:

```json
{
  "type": "sync",
  "status-code": 200,
  "status": "OK",
  "result": [
    {
      "id": 40,
      "snapshots": [
        {
          "set": 40,
          "time": "2020-12-16T11:52:00.689328169Z",
          "snap": "<snap-name>",
          "revision": "x2",
          "epoch": {
            "read": [
              0
            ],
            "write": [
              0
            ]
          },
          "summary": "",
          "version": "6.0",
          "sha3-384": {
            "archive.tgz": "31fcc9cce5b5cdc68aeb38e3ef3866f00174dba158bce23870962b7dee12c1ec49a434346f6e8c7a1209858fb95e8020",
            "user/<username>.tgz": "e19ab68a4aef50468667b873aefa83813919851b931b60782b0d8e4d6d12021402c757002ba3738855ed9e8da1268c50"
          },
          "size": 846235,
          "options": {
            "exclude": [
              "$SNAP_DATA/*.bak", 
              "$SNAP_COMMON/exclude",
              "$SNAP_USER_DATA/large-files",
              "$SNAP_USER_COMMON/.cache"        
            ]
          }
        }
      ]
    }
  ]
}
```

## GET /v2/snapshots[/{set-id}]/export

* Description: exports the snapshot with given set-id
* Access: authenticated
* Operation: sync
* Return: stream of snapshot data

The set-id is the snapshot identifier retrieved either from the 'snap saved' command or [GET /v2/snapshots](#heading--snapshots).

The response has `Content-Type: application/x.snapd.snapshot` and Content-Length headers, plus the data stream which contains an uncompressed tar archive containing multiple zip files inside (one zip file for every snap included in the snapshot). The details of stream format might change, it is mainly intended for importing via `POST /v2/snapshots`.

## POST /v2/snapshots

* Description: manipulate or import a snapshot
* Access: authenticated
* Operation: see each operation category
* Return:  see each operation category

Snapshots based on current installed snap data are created via [`POST /v2/snaps`](#heading--snapshot-create).

### Snapshot manipulation

* Description: restore, check or forget a snapshot
* Access: authenticated
* Operation: async
* Return: background operation or standard error
 
Example:

```yaml 
{
   "action": "restore",
   "set": 35,
   "snaps": ["snap1"],
   "users":  ["user1"],
}
```

### Fields

* `action`: either restore, check or forget
* `set`: the id of the _snapshot set_ to operate on
* `snaps`: array of snap names to restrict the action to (optional)
* `users`: array of user names to restrict the action to (only for restore, optional)

### Snapshot import

* Operation: sync
* Return: the set-id of the imported snapshot and names of the snaps

### Request headers:

Content-Type: application/x.snapd.snapshot
Content-Length: \<size of the imported snapshot\>

 The request body should contain the snapshot data (i.e. a tar archive of an exported snapshot).

### Response

Example:
```yaml
{
 "type": "sync",
 "result": {
      "set": 42,
        "snaps": [
         "foo",
         "bar" 
      ]
  }
}
```
---

## GET /v2/system-info

* Description: server configuration and environment information
* Access: open
* Operation: sync
* Return: dict with the operating system's key values

### Response

Example:

```javascript
{
    "architecture": "amd64",
    "build-id": "524d4b73702d554259465f5636394134783251482f554a5075625a724e6d72524f42774b78566e33442f423354555f2d3449767859315437645171554b432f5a47334c4859716e4a634b5550645241466b584e",
    "confinement": "strict",
    "features": {
        "apparmor-prompting": {
            "supported": false,
            "unsupported-reason": "requires newer version of snapd",
            "enabled": false
        },
        "aspects-configuration": {
            "supported": true,
            "enabled": false
        },
        "check-disk-space-install": {
            "supported": true,
            "enabled": false
        },
        "check-disk-space-refresh": {
            "supported": true,
            "enabled": false
        },
        "check-disk-space-remove": {
            "supported": true,
            "enabled": false
        },
        "classic-preserves-xdg-runtime-dir": {
            "supported": true,
            "enabled": true
        },
        "dbus-activation": {
            "supported": true,
            "enabled": true
        },
        "gate-auto-refresh-hook": {
            "supported": true,
            "enabled": false
        },
        "hidden-snap-folder": {
            "supported": true,
            "enabled": false
        },
        "hotplug": {
            "supported": true,
            "enabled": false
        },
        "layouts": {
            "supported": true,
            "enabled": true
        },
        "move-snap-home-dir": {
            "supported": true,
            "enabled": false
        },
        "parallel-instances": {
            "supported": true,
            "enabled": false
        },
        "per-user-mount-namespace": {
            "supported": true,
            "enabled": false
        },
        "quota-groups": {
            "supported": true,
            "enabled": false
        },
        "refresh-app-awareness": {
            "supported": true,
            "enabled": true
        },
        "refresh-app-awareness-ux": {
            "supported": true,
            "enabled": false
        },
        "robust-mount-namespace-updates": {
            "supported": true,
            "enabled": true
        },
        "snapd-snap": {
            "supported": true,
            "enabled": false
        },
        "user-daemons": {
            "supported": true,
            "enabled": false
        }
    },
    "kernel-version": "6.5.0-26-generic",
    "locations": {
        "snap-bin-dir": "/snap/bin",
        "snap-mount-dir": "/snap"
    },
    "managed": false,
    "on-classic": true,
    "os-release": {
        "id": "ubuntu",
        "version-id": "23.10"
    },
    "refresh": {
        "timer": "00:00~24:00/4",
        "last": "2024-04-02T16:27:00-05:00",
        "next": "2024-04-02T22:55:00-05:00"
    },
    "sandbox-features": {
        "apparmor": [
            "kernel:caps",
            "kernel:dbus",
            "kernel:domain",
            "kernel:domain:attach_conditions",
            "kernel:file",
            "kernel:io_uring",
            "kernel:ipc",
            "kernel:mount",
            "kernel:namespaces",
            "kernel:network",
            "kernel:network_v8",
            "kernel:policy",
            "kernel:policy:unconfined_restrictions",
            "kernel:policy:versions",
            "kernel:ptrace",
            "kernel:query",
            "kernel:query:label",
            "kernel:rlimit",
            "kernel:signal",
            "parser:cap-audit-read",
            "parser:cap-bpf",
            "parser:include-if-exists",
            "parser:mqueue",
            "parser:qipcrtr-socket",
            "parser:snapd-internal",
            "parser:unconfined",
            "parser:unsafe",
            "parser:userns",
            "parser:xdp",
            "policy:default",
            "support-level:full"
        ],
        "confinement-options": [
            "classic",
            "devmode",
            "strict"
        ],
        "dbus": [
            "mediated-bus-access"
        ],
        "kmod": [
            "mediated-modprobe"
        ],
        "mount": [
            "layouts",
            "mount-namespace",
            "per-snap-persistency",
            "per-snap-profiles",
            "per-snap-updates",
            "per-snap-user-profiles",
            "stale-base-invalidation"
        ],
        "seccomp": [
            "bpf-actlog",
            "bpf-argument-filtering",
            "kernel:allow",
            "kernel:errno",
            "kernel:kill_process",
            "kernel:kill_thread",
            "kernel:log",
            "kernel:trace",
            "kernel:trap",
            "kernel:user_notif"
        ],
        "udev": [
            "device-cgroup-v2",
            "device-filtering",
            "tagging"
        ]
    },
    "series": "16",
    "system-mode": "run",
    "version": "2.62"
}

```

#### Fields

* `architecture`: the CPU architecture of the host system
* `build-id`: a unique ID for this build of snapd
* `confinement`: the level of confinement the system supports; either `strict` or `partial`
* `features`: dict mapping snapd feature names to information about whether that feature is supported and/or enabled
* `kernel-version`: version of the kernel on this system
* `locations`: dict containing directory locations used by snapd (see below)
* `managed`: true if able to manage user accounts (?)
* `on-classic`: true if not running on a fully snap managed system
* `os-release`: object containing release information as sourced from `/etc/os-release`. Contains `id` which is a unique ID for each OS and `version-id` which is a string describing the version of this OS
* `refresh`: dict containing refresh times (optional, see below)
* `sandbox-features`: dict containing information information about features supported by various components of the sandbox
* `series`: the core series in use
* `system-mode`: the mode under which snapd is operating; either `run`, `recover`, or `install` (absent on pre-UC20 systems)
* `version`: the version of snapd
* `store`: the name of the store being used (optional, omitted if using the standard store)

#### Location fields

* `snap-mount-dir`: directory where snaps are mounted in
* `snap-bin-dir`: directory where snap apps are run from

#### Refresh fields

* `last`: last time a refresh was performed (optional)
* `next`: next time a refresh will be performed
* `hold`: time that refreshes will be applied (optional, if missing then applied immediately)
* `timer`: times that updates are checked for
* `schedule`: schedule that updates are being checked with (legacy, replaced with `timer`)

---
## GET /v2/systems

* Description: get the list of recovery systems
* Access: open
* Operation: sync
* Return: list of recovery systems

### Response

```javascript
"systems": [
            {
                "actions": [
                    {
                        "mode": "install",
                        "title": "Reinstall"
                    },
                    {
                        "mode": "recover",
                        "title": "Recover"
                    },
                    {
                        "mode": "factory-reset",
                        "title": "Factory reset"
                    },
                    {
                        "mode": "run",
                        "title": "Run normally"
                    }
                ],
                "brand": {
                    "display-name": "Canonical",
                    "id": "canonical",
                    "username": "canonical",
                    "validation": "verified"
                },
                "current": true,
                "label": "20220518",
                "model": {
                    "brand-id": "canonical",
                    "display-name": "ubuntu-core-22-pi-arm64-dangerous",
                    "model": "ubuntu-core-22-pi-arm64-dangerous"
                }
            }
        ]
```

### Fields

* `current`: current is true when the system running now was installed from this recovery system seed
* `label`: the label for this recovery system
* `model`: the model assertion information associated with this recovery system
* `brand`: the brand information associated with the model that this recovery system has
* `actions`: actions available for this system

#### Model assertion information fields

* `model`: the model name from the model assertion
* `brand-id`: the brand-id from the model assertion
* `display-name`: the display name of the model from the model assertion

#### Brand information fields

* `username`: the username of the brand from the account assertion
* `id`: the account-id of the brand account assertion
* `display-name`: the display name of the brand from the account assertion
* `validation`: the validation status from the brand account assertion (see the brand account assertion docs for the valid values of this)

#### Action fields

* `mode`: the mode that the system transitions to when executing the given action
* `title`: a user presentable description of taking this action

## POST /v2/systems

* Description: attempt to perform an action with the current active recovery system
* Access: root
* Operation: sync
* Return: 200 OK or an error

Example response:

```javascript
{
    "action": "reboot",
    "mode": "run"
}

{
  "action": "create",
  "label": "some-label",
  "test-system": false,
  "mark-default": false,
  "validation-sets": ["id1/validation-set1=2", "id2/validation-set2"],
  "offline": false,
}

{
    "action": "do",
    "mode": "recover"
}

{
    "action": "do",
    "mode": "install",
}

{
    "action": "do",
    "mode": "factory-reset"
}
```

### Fields

* `action`: action to perform, which is either "reboot", "create" or "do".

  The "reboot" action will always reboot the device to the specified mode, even if the specified system and mode are the current system and mode.

  The "create" action will attempt to create a recovery system. See [Create a recovery system using the REST API](https://ubuntu.com/core/docs/recovery-system-api) for further details.

  The "do" action is meant to consume fields of an action as provided in the actions list under the system in the response from a GET request to /v2/systems. Currently "mode" is the only such field, but there may be more fields added that correspond to additional details about the action that can be taken with the system. If the "do" action is provided for the current system and the current mode then no action is taken. For the current active recovery system, specifying a different mode from the current mode (and no other additional fields are specified with "do"), the actions "do" or "reboot" are equivalent.

* `mode`: the mode to transition to. Modes "run" and "recover" are only available for the current active recovery system.

  The "install" and "factory-reset" modes are always available for all recovery systems and will trigger either a full system install or a re-initialisation of the device to its factory state, with both modes deleting all user and system data

See [Recovery modes](https://ubuntu.com/core/docs/recovery-modes) for more details on each supported recovery mode, what they do, and how they can be used.

---

## GET /v2/system-recovery-keys

* Description: retrieve LUKS encryption keys when using full disk encryption on Ubuntu Core
* Access: authenticated
* Operation: sync
* Return: recovery key

### Response

Example:

```json
{
    "result": {
        "recovery-key": "14697-25590-04585-06938-46886-23115-29787-34072"
    },
    "status": "OK",
    "status-code": 200,
    "type": "sync"
}

```

## POST /v2/system-recovery-keys

* Description: removes and resets LUKS encryption keys when using full disk encryption on Ubuntu Core
* Access: authenticated
* Operation: sync
* Return: success or error code

### Fields

* `action`: the only action currently supported is `remove` to remove and reset the encryption keys stored as LUKS metadata when using full disk encryption (FDE) on Ubuntu Core devices

See [Using recovery keys](https://ubuntu.com/core/docs/use-recovery-mode#heading--recovery-keys) for more information.

### Response

Example:

```json
{
    "result": null,
    "status": "OK",
    "status-code": 200,
    "type": "sync"
}
```

---

## POST /v2/systems[/{label}]

* Description: attempt to perform an action with the specified recovery system, identified by its label
* Access: root
* Operation: sync
* Return: 200 OK or an error
* Same fields and usage as [POST to /v2/systems/](#heading--systems-post)

## GET /v2/users

* Description: get information on user accounts
* Access: root
* Operation: sync
* Return: array of user account information

### Response

Example:
```javascript
[
    {
        "email": "first-name.last-name@example.com",
        "id": 1,
        "username": "lp-username2"
    },
    {
        "email": "other.name@example.com",
        "id": 2,
        "username": "user2"
    },
]
```

#### Fields

* `email`: email address associated with this account
* `id`: unique ID for this user account
* `username`: local username associated with this account (optional)

## POST /v2/users

* Description: create or remove local users
* Access: root
* Operation: sync
* Return: list of objects with the created user details

### Request

Example:
```javascript
{
    "action": "create",
    "username": "demo_user",
    "email": "demo@exampledomain.com",
    "sudoer": false
}
```

#### Fields

* action: action to perform, either "create" or "remove"
* email: the email of the user to create or remove
* username: the username of the user to create or remove
* sudoer: if true, adds "sudo" access to a created user
* known: if true, use the local system-user assertions to create the user
         (see assertions.md for details about the system-user assertion).
* force-managed: force adding the user even if the device is already managed
* automatic: if true, permits managed devices to create users via the API without generating an error. The [system.users.create.automatic](/t/system-options/29860#heading--users-create-automatic) system option also needs to be set to **false**

As a special case: if email is empty and known is set to true, the
command will create users for all system-user assertions that are
valid for this device.

### Response

Example:
```javascript
[
    {
        "username": "mvo",
        "ssh-keys": ["key1","key2"]
    }
]
```

#### Fields

* id: the id of the user
* username: the username of the user
* ssh-keys: a list of strings with the ssh keys that got added

---

## GET /v2/validation-sets

* Description: get all enabled [validation sets](/t/validation-sets/23801)
* Access: authenticated
* Operation: sync
* Return: list of validation sets

#### Response

Example:

```json	
[
    {
        "account-id": "xSfWAGdL56BoQxuuvIM90pbFNMq23t1f",
        "name": "bar",
        "mode": "monitor",
        "pinned-at": 2,
        "sequence": 3,
        "valid": false
    },
    {
        "account-id": "xSfWAGdL56BoQxuuvIM90pbFNMq23t1f",
        "name": "baz",
        "mode": "enforce",
        "sequence": 1,
        "valid": true
    }
]
```

#### Fields

- `account-id`: identifier for the developer account (creator of the validation-set).
- `name`: name of the validation set.
- `mode`: mode of the validation set in the system, either "monitor" or enforce".
- `pinned-at`: only set (greater than 0) if the validation set is pinned at a specific sequence number.
- `sequence`: current sequence value of the validation set assertion.
- `valid`: reports  whether the validation set is valid for the currently installed snaps.

## GET /v2/validation-sets[/{account-id}/{name}]

* Access: authenticated
* Operation: sync
* Return: either a single validation-set dict, or an error

### Response

Example:

```json
{
     "account-id": "xSfWAGdL56BoQxuuvIM90pbFNMq23t1f",
     "name": "bar",
     "mode": "monitor",
     "pinned-at": 2,
     "sequence": 3,
     "valid": false
},
```

For a description of the fields returned by this request, see [`GET /v2/validation-sets`](#heading--validation-sets-fields) above.

## POST /v2/validation-sets/[account-id]/[name]

- Access: authenticated
- Operation: sync
- Return: 200 OK or an error

### Request

Example:

```json
{
    "action": "apply",
    "mode": "monitor",
    "sequence": 3
}
```

#### Fields

- `action`: action to perform. Must be either "apply" or "forget".
- `mode`: only for the "apply" action. This specified the mode to enable for the validation-set. Can be either "monitor" or "enforce".
- `sequence`: an optional sequence number to pin at with "apply". If passed with "forget", then the validation set will only be forgotten if it is pinned at the given sequence (404 error will be returned if pinned at a different sequence).

---

## GET /v2/warnings

* Description: get the warnings in snapd
* Access: open
* Operation: sync
* Return: list containing the warning messages

### Response

Example:
```javascript
[
    {
        "message": "hello world",
        "first-seen": "2017-01-23T12:00:44.806931498+13:00",
        "last-seen": "2017-01-23T12:00:44.806931498+13:00"
    },
    {
        "message": "hello again",
        "first-seen": "2017-01-23T12:00:44.806931498+13:00",
        "last-seen": "2017-01-23T12:00:44.806931498+13:00",
        "delete-after": "1h30m"
    },
]
```

#### Warning Fields

* `message`: message for this warning
* `first-seen`: the first time one of these messages was created in RFC3339 UTC format
* `last-seen`: the last time one of these messages was created in RFC3339 UTC format
* `last-shown`: the last time one of these messages was shown to the user in RFC3339 UTC format (optional)
* `delete-after`: how much time since one of these was last seen should we drop the message (optional)
* `repeat-after`: how much time since one of these was last shown should we repeat it (optional)

The durations are in the form "72h3m0.5s" or "1us" or "1ns".

## POST /v2/warnings

* Description: respond to warnings
* Access: authenticated
* Operation: sync
* Return: 200 OK or an error

### Request

Example:
```javascript
{
    "action": "okay",
    "timestamp": "2017-01-23T12:00:44.806931498+13:00"
}
```

#### Fields

* `action`: must be `okay`
* `timestamp`: time to clear warnings before in RFC3339 UTC format

-------------------------

degville | 2020-06-03 07:57:35 UTC | #2



-------------------------

degville | 2020-07-13 08:40:00 UTC | #3



-------------------------

kyleN | 2021-05-25 18:45:59 UTC | #4

[quote="mborzecki, post:1, topic:17954"]
GET /v2/snaps/[name]/conf
[/quote]

Can this section also state that to get `system` config values, the snap [name] should be `system`?

-------------------------

pedronis | 2021-05-26 11:29:05 UTC | #5

made `configuration` its own subsection and mentioned that.

-------------------------

snowsky | 2021-06-01 18:33:23 UTC | #6

Is there an API for `snap refresh --list`? Thanks. :slight_smile:

-------------------------

pedronis | 2021-06-02 07:54:39 UTC | #7

Yes, it's also documented, but its placement is not the most obvious.  It is implemented as `/v2/find?select=refresh`.

-------------------------

kyleN | 2021-09-29 14:28:39 UTC | #8

Apparently there is an enpoint to download a snap, but it is not documented. Can this please be added?

-------------------------

degville | 2021-09-29 14:43:51 UTC | #9

Thanks for mentioning this. I'll ask the team for the best method and update the docs.

-------------------------

kyleN | 2021-09-29 17:42:54 UTC | #10


The docs don't seem to say how to get a **remote** assertion. The following succeeds in getting a remote snap-declaration assertion from a `sudo snap run --shell APP` shell (with snapd-control connected) for the specified snap-id

`$SNAP/usr/bin/curl -sS -X GET --unix-socket /run/snapd.socket "http://localhost/v2/assertions/snap-declaration?series=16&remote=true&snap-id=OHILDGdP7v0yZmkQnvGyXnGD5t2mZZ1g"
`

-------------------------

degville | 2021-10-06 13:24:28 UTC | #11

Thanks for suggesting this. I've added a brief explanation - let me know if we need to expand on this.

-------------------------

woodrow | 2022-01-20 12:35:38 UTC | #12

Hi,

When I tried to create/remove a user from rest API, I didn't see any piece to mention how to remove a user, in my opinion, the doc should add more about user removal. I did trial and error to get it working via `{"action":"remove","username":"yourname"}`.

-------------------------

rpjday | 2022-02-25 12:59:08 UTC | #13

Is this list supposed to be complete, as there appear to be a number of other requests defined under snapd/daemon, such as cohort and quotas and more. If you follow the link "Using the REST API", that page refers back to this page as a "reference", suggesting it really should cover all possibilities. Otherwise, where does one get a comprehensive list of REST API requests short of looking at the source?

-------------------------

alexclewontin | 2022-03-07 17:02:44 UTC | #14

A minor nitpick: looks like the endpoint for `POST 2/validation-sets/[account-id]/[name]` is missing a `v`

-------------------------

degville | 2022-03-07 17:10:56 UTC | #15

[quote="alexclewontin, post:14, topic:17954"]
A minor nitpick
[/quote]

Not a nitpick! It really should have been there :) thanks for reporting it. I've updated the endpoint.

-------------------------

kyleN | 2022-03-15 13:08:25 UTC | #16

Hi - just checking whether the download endpoint documentation is coming. Cheers

-------------------------

alexclewontin | 2022-03-15 19:10:43 UTC | #17

[quote="mborzecki, post:1, topic:17954"]
## POST /v2/users

* Description: Create or remove local users.
* Access: root
* Operation: sync
* Return: List of objects with the created user details.

### Request

Example:

```
{
    "action": "create",
    "email": "michael@example.com",
    "sudoer": false
}
```

#### Fields

* action: Action to perform, either “create” or “remove”.
* email: the email of the user to create.
* sudoer: if true adds “sudo” access to the created user.
* known: if true use the local system-user assertions to create the user (see assertions.md for details about the system-user assertion).
* force-managed: force adding the user even if the device is already managed.

As a special case: if email is empty and known is set to true, the command will create users for all system-user assertions that are valid for this device.

### Response

Example:

```
[
    {
        "username": "mvo",
        "ssh-keys": ["key1","key2"]
    }
]
```

#### Fields

* id: the id of the created user
* username: the username of the created user.
* ssh-keys: a list of strings with the ssh keys that got added.
[/quote]

Not sure what the best way to document this is, but it would be helpful to elaborate on the Request fields for `"action": "create"` and `"action": "remove"` separately, as when `action` is `remove`, you need only a `username` field which this does not make readily apparent.
