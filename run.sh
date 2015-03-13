#!/bin/sh
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
    bundle_command="$bundle_command --without $WERCKER_BUNDLE_INSTALL_WITHOUT"
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

if [ -n "$WERCKER_BUNDLE_INSTALL_JOBS" ] ; then
    if [ "$WERCKER_BUNDLE_INSTALL_JOBS" -gt 0 ] ; then
        bundle_command="$bundle_command --jobs=$WERCKER_BUNDLE_INSTALL_JOBS"
    fi
fi

if [ -z "$WERCKER_BUNDLE_INSTALL_VERSION" ] ; then
    export WERCKER_BUNDLE_INSTALL_VERSION=">=1.5.2"
fi

install_bundler() {
    # Install bundler gem if needed
    if ! type bundle &> /dev/null; then
         info 'bundler gem not found, starting installing it';
         sudo gem install bundler --no-rdoc --no-ri --version "$WERCKER_BUNDLE_INSTALL_VERSION";

         if [[ $? -ne 0 ]]; then
             fail 'bundler gem installation failed';
         else
             info 'finished bundler gem installation';
         fi
    else
        info 'bundler gem is available, and will not be installed by this step';
    fi

    debug "type bundle: $(type bundle)";
    debug "bundle version: $(bundle --version)";
}

if [ ! -e "$PWD/Gemfile" ]; then
    info "Skipping bundle install because Gemfile not found in $PWD";
else
    info 'Gemfile found. Start bundle install.';

    install_bundler;

    debug "$bundle_command";
    $bundle_command;

    if [[ $? -ne 0 ]]; then
        fail 'bundle install command failed';
    else
        success "finished $bundle_command";
    fi

    if ! type rbenv &> /dev/null ; then
        debug 'skipping rbenv rehash because rbenv is not found';
    else
        debug 'rbenv is found... will rehash';
        debug 'rbenv rehash';
        rbenv rehash;
        info 'rbenv rehash completed';
    fi
fi
