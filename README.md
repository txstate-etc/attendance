# Attendance
Attendance is a Ruby on Rails application developed at Texas State University for tracking course attendance.

## Note on LTI Compatability
Attendance serves as an LTI tool provider and should work with any LMS that can act as an LTI tool consumer (see http://www.imsglobal.org/lti/). While the tool was developed to be LMS agnostic, it does depend on the context memberships service to retrieve rosters and the outcomes service to report grades. Support for these services may vary from one LMS to another. Grades reporting is optional, but the context memberships service is required for the tool to function properly.

## Initial set up

#### Install RVM (https://rvm.io/rvm/install)

#### Bundle install

NOTE: you may need to install libxml2-dev and libmysqlclient-dev for bundle install to complete successfully

#### Create config/initializers/secret_token.rb
Use the rake secret command to generate a random secret token.
```
echo Attendance::Application.config.secret_token = \'`rake secret`\' > config/initializers/secret_token.rb
```

#### Create config/initializers/oauth_secret.rb 
This is the secret key to be used with LTI.
```
echo Attendance::Application.config.oauth_secret = \'`rake secret`\' > config/initializers/oauth_secret.rb
```

#### Create config/initializers/auth.rb
You'll need to create this file if you want to specify the user and password to be used to connect to mysql. Config/database.yml defaults to using root user with no password.
```
MYSQL_USER = '<user>' unless defined? MYSQL_USER
MYSQL_PASSWORD = '<password>' unless defined? MYSQL_PASSWORD
```

#### Copy default environments (TODO: there should be a better way to do this)
A default application.rb as well as default staging and production environments can be found in config/. The development environment is already in place.
```
cd config
mv application_default.rb application.rb
cd environments
mv production_default.rb production.rb
mv staging_default.rb staging.rb
```

#### CAS configuration (TODO: add other auth options)
Developers and administrators may need to access the tool directly instead of through an LTI launch. Attendance can be configured to use CAS at the bottom of application.rb. Comment out these lines if you won't be using CAS as an alternate means of authentication.

```
config.rubycas.cas_base_url = 'https://your.cas.server.edu'
config.rubycas.logger = Rails.logger
config.rubycas.enable_single_sign_out = true
```
To log in using CAS, visit /roles.

#### Create/load database

Run the following command to create the database and seed it with data found in db/seeds.rb

```
rake db:setup
```

#### Start server

At this point you should be able to start the rails server

```
rails s --debugger
```

## Configuring Sakai

### [Optional] Apply provided patch
Apply the appropriate patch for your sakai version, found in sakai/. This patch contains the following updates to the basiclti tool:

* send provider ids in the roster service so that attendance can be taken separately for different sections
* ability to map sakai roles to LTI roles (will be part of Sakai 11)
* custom lti service for setting the max points of the gradebook item to the number of attendances
* use an external gradebook item if imsti.useExternalGbAssign is set to true

### Add IMSBLTIPortlet.xml
Tool registration for attendance tool should be configured in a IMSBLTIPortlet.xml file at sakai.home/portlets/imsblti/IMSBLTIPortlet.xml
```
<tool id="sakai.attendance" title="Attendance" description="For tracking attendance.">
    <category name="course" />
    <category name="project" />

    <configuration name="imsti.launch" value="asdf" />
    <configuration name="imsti.xml" />
    <configuration name="imsti.secret" value="asdf" />
    <configuration name="imsti.key" value="asdf" />
    <configuration name="imsti.pagetitle" value="Attendance" />
    <configuration name="imsti.tooltitle" value="Attendance" />
    <configuration name="imsti.newpage" value="false"/>
    <configuration name="imsti.maximize" />
    <configuration name="imsti.frameheight" />
    <configuration name="imsti.debug" />
    <configuration name="imsti.releasename" value="on" />
    <configuration name="imsti.releaseemail" value="on" />
    <configuration name="imsti.releasestatus" value="on" />
    <configuration name="imsti.releaseproviders" value="on" />
    <configuration name="imsti.useExternalGbAssign" value="true" />
    <configuration name="imsti.hideClearPreferences" value="true" />
    <configuration name="imsti.custom" />
    <configuration name="imsti.allowsettings" />
    <configuration name="imsti.allowroster" value="on" />
    <configuration name="imsti.contentlink" />
    <configuration name="imsti.rolemap" value="ta:TeachingAssistant,maintain:Learner/Instructor,access:Member,Guest:Learner/GuestLearner,Site Assistant:Instructor/GuestInstructor,Site Collaborator:Instructor/ExternalInstructor,Grader:TeachingAssistant/Grader" />
    <configuration name="imsti.splash" />

    <configuration name="final.launch" value="true"/>
    <configuration name="final.xml" value="true"/>
    <configuration name="final.secret" value="true"/>
    <configuration name="final.key" value="true"/>
    <configuration name="final.pagetitle" value="true"/>
    <configuration name="final.tooltitle" value="true"/>
    <configuration name="final.newpage" value="true"/>
    <configuration name="final.maximize" value="true"/>
    <configuration name="final.frameheight" value="true"/>
    <configuration name="final.debug" value="true"/>
    <configuration name="final.releasename" value="true"/>
    <configuration name="final.releaseemail" value="true"/>
    <configuration name="final.custom" value="true"/>
    <configuration name="final.allowsettings" value="true"/>
    <configuration name="final.allowroster" value="true"/>
    <configuration name="final.contentlink" value="true"/>
    <configuration name="final.splash" value="true"/>
    <configuration name="final.allowlori" value="true"/>

    <configuration name="allowMultipleInstances" value="false" />
  </tool>
  ```
  
**NOTE: The value for imsti.rolemap will depend on what roles you have set in your sakai instance and how you want them mapped to LTI roles. It should be a comma-separated list of values with the form 'sakairole:ltirole'.

### Properties
The following properties must be set in a sakai properties file.
```
basiclti.provider.enabled=true
basiclti.outcomes.enabled=true
basiclti.roster.enabled=true

sakai.attendance.launch=http://localhost:3000/lti_tool
# The key must be set to notused. Any other value will cause a validation error.
sakai.attendance.key=notused
sakai.attendance.secret=yoursecret
```
