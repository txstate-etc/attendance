#!/bin/bash

# just run this once in the first time of db creation
#database.yml just created db attendance, but won't create tables and pop initial database
# but tables created will be empty

# rake db:reset

 rake db:setup