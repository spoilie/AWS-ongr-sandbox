# ONGR sandbox on AWS platform.

This is an OpsWorks template which sets up 3 layers for your ONGR testing environment: a jenkins instance, ONGR sandbox instance and an e-shop (Oxid CE). 

### Install instructions

1. Download the CloudFormer template `AWS-template` from this repository and use it to create an OpsWors stack in your AWS cloud. This is done via the `CloudFormation` section in your AWS console. Currently, this template is tailored for Frankfurt region, so you need to switch to it before creating your stack. If you wish to import the template onto another region, you need to change the `DefaultAvailabilityZone` setting in your template. In the `CloudFormation` section Select `Create`, then `Upload a template to Amazon S3` and browse to the template you downloaded from this repo. Name your stack anything you'd like and leave all other settings unchanged. 

2. After the stack is created, you need to make some modifications to it before bringing it up. In order to be able to ssh to your instances, you need to add your public key in `EC2 Dashboard` -> `Key Pairs` (under Network and Security). If you haven't already done so, import your public key in this section and then edit your stack configuration. Under `OpsWorks` section, select `Stack Settings` of the newly created stack and change `Default SSH key` to the key you just imported. It is recommended to fork this repo to yourself and customize it to your needs. If you decide to do so, you should also change the `Repository URL` under your stack settings as well. 

3. Create an S3 bucket and create an IAM user with full access to S3. This will be used to store Jenkins build archives of your application. Save the user credentials and paste them into the attribute file at `base/attribute/default.rb` of your repository along with the bucket name and other settings you wish to customize. For security purposes, you should not commit this file to be available publicly. The same credentials should be used for the OpsCodes app deployment. Under `Apps` section, edit your application deployment settings - select `Data source type` as `none` and add your S3 user credentials (Access Key ID and Secret Access Key) and modify the URL to suit your bucket name: https://{your-s3-bucket-name}.s3.amazonaws.com/ongr-sandbox.tar.gz

4. Every cookbook attribute is located inside respestive cookbook's directory. Use these files to customize various configuration options of your stack layers:

   * [dev instance attributes](dev/attributes/default.rb)

   * [jenkins instance attributes](myjenkins/attributes/default.rb)

   * [oxid instance attributes](oxideshop/attributes/default.rb)
5. Navigate to your stack `Instances` section. Add an instance to each layer. 
  In order to access instances via browser, please add respective IP addresses to the hosts file, e.g. `/etc/hosts`:

  ```
  53.93.164.45 ongr.dev
  53.93.184.57 jenkins.dev
  53.93.112.33 oxid.dev
  ```
  The Jenkins build is named 'master_build' and it uses `git@github.com:kazgurs/ongr-sandbox.git` repository by default (it's defined in jenkins cookbook attributes). Change this attribute to your forked repo and edit the instance IP address inside `app/deploy/stage.rb`, e.g.:
  
  `server '52.93.174.32', user: 'ubuntu', roles: %w{web app}`
  
  Start the `jenkins` instance first. After the setup is successful, access it via `jenkins.dev` host you created earlier. Double check the S3 credentials via global jenkins settings. Also, make sure you have the correct s3-bucket region selected in the `master_build` options under post-build actions. You may find region naming [here](http://docs.aws.amazon.com/general/latest/gr/rande.html#s3_region). Run the `master_build`. After your build is successful, you should see the .tar.gz archive placed in your S3 bucket. This will be pulled during your `dev` instance provisioning, so you can go ahead and start the `dev` and `oxid` instances now.

6. To populate ONGR with demo data, you need to ssh into the server (`ssh ubuntu@dev_instance_IP`) and switch to the dev user (`su dev`). Under ongr document root `/srv/www/ongr_sandbox/current/` run these commands:

  ```
  app/console ongr:es:index:create -e prod
  
  app/console ongr:es:index:import --raw src/ONGR/DemoBundle/Resources/data/categories.json -e prod

  app/console ongr:es:index:import --raw src/ONGR/DemoBundle/Resources/data/products.json -e prod

  app/console ongr:es:index:import --raw src/ONGR/DemoBundle/Resources/data/contents.json -e prod
  
  app/console assetic:dump
  ```
  This only needs to be done once. To execute the build, you can call the jenkins API or run the build manually. The deployment can be run by calling AWS API or re-running the `depl` recipe via `Deployments` -> `Run command` section. 
### What's inside

* all instances comprise of LEMP stacks with nginx, php5-fpm and MySQL 5.5
* jenkins stack:
    * plugins: git, rbenv, ruby-runtime, scm-api, s3
* ongr stack:
    * Java 1.7 JDK, elasticsearch 1.7.1, git, composer, nodejs, compass, xdebug, phantomjs
* oxid stack:
    * Oxid CE on LEMP stack
