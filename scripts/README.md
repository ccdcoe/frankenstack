# Scripts

Not everything needs to be in a manifest. Sometimes 50 lines of python is all you need to automate a tedious task or save the day.

## Getting started

See [requirements](/requirements.txt) for python dependencies. Additionally, kafka messages are compressed with Snappy compression library. Python bindings depend on libsnappy. On Debian/Ubuntu, run:

```
apt-get install libsnappy-dev
```
