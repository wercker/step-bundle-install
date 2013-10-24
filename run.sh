#!/bin/sh
cd $WERCKER_ROOT
bundle_command="bundle install"

if [ -z "$WERCKER_BUNDLE_INSTALL_PATH" ] ; # Check $WERCKER_BUNDLE_INSTALL exists
then
    if [ -n "$WERCKER_BUNDLE_INSTALL_PATH" ]; # Check $WERCKER_BUNDLE_INSTALL exists and is not empty
    then
        bundle_command="$bundle_command --path $WERCKER_BUNDLE_INSTALL_PATH"
    else
        bundle_command="$bundle_command --path $WERCKER_CACHE_DIR/bundle-install/"
    fi
fi

if [ -n "$WERCKER_BUNDLE_INSTALL_WITHOUT" ] ; then
    bundle_command="$bundle_command --without \"$WERCKER_BUNDLE_INSTALL_WITHOUT\""
fi

if [ "$WERCKER_BUNDLE_INSTALL_STANDALONE" = "true" ] ; then
    bundle_command="$bundle_command --standalone"
fi

if [ "$WERCKER_BUNDLE_INSTALL_BINSTUBS" = "true" ] ; then
    bundle_command="$bundle_command --binstubs"
fi

if [ "$WERCKER_BUNDLE_INSTALL_CLEAN" = "true" ] ; then
    bundle_command="$bundle_command --clean"
fi

if [ "$WERCKER_BUNDLE_INSTALL_FULL_INDEX" = "true" ] ; then
    bundle_command="$bundle_command --full-index"
fi

if [ "$WERCKER_BUNDLE_INSTALL_DEPLOYMENT" = "true" ] ; then
    bundle_command="$bundle_command --deployment"
fi

if [ "$WERCKER_BUNDLE_INSTALL_LOCAL" = "true" ] ; then
    bundle_command="$bundle_command --local"
fi

if [ "$WERCKER_BUNDLE_INSTALL_FROZEN" = "true" ] ; then
    bundle_command="$bundle_command --frozen"
fi

if [ ! "$PWD" = "$WERCKER_SOURCE_DIR" ] ; then
    debug "changing directory from $PWD to $WERCKER_SOURCE_DIR"
    cd $WERCKER_SOURCE_DIR
fi

# Install bundler gem if needed
if ! type bundle &> /dev/null ;
then
     info 'bundler gem not found, starting installing it'
     sudo gem install bundler --no-rdoc --no-ri --version '1.3'

     if [[ $? -ne 0 ]];then
         fail 'bundler gem installation failed';
     else
         info 'finished bundler gem installation';
     fi
else
    debug "type bundle: $(type bundle)"
    debug "bundle version: $(bundle --version)"
    info 'bundler gem is available, and will not be installed by this step'
fi

if [ ! -e "$WERCKER_SOURCE_DIR/Gemfile" ] && [ ! -e "$WERCKER_SOURCE_DIR/gemfile" ] ; then
    warn "Skipping bundle install because Gemfile not found in $WERCKER_SOURCE_DIR"
else
    info 'Gemfile found. Start bundle install.'
    debug "$bundle_command"
    $bundle_command

    if [[ $? -ne 0 ]]
    then
        fail 'bundle install command failed'
    else
        success "finished $bundle_command"
    fi

    if ! type rbenv &> /dev/null ; then
        debug 'skipping rbenv rehash because rbenv is not found'
    else
        debug 'rbenv is found... will rehash'
        debug 'rbenv rehash'
        rbenv rehash
        info 'rbenv rehash completed'
    fi
fi
