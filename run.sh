#!/bin/sh
bundle_command="bundle install"
gemfile_name="Gemfile"
default_cache_path="$WERCKER_CACHE_DIR/bundle-install/"
install_path=""
try=1
MAX_TRIES=3

if [ -z "$WERCKER_BUNDLE_INSTALL_PATH" ] ; # Check $WERCKER_BUNDLE_INSTALL exists
then
    if [ -n "$WERCKER_BUNDLE_INSTALL_PATH" ]; # Check $WERCKER_BUNDLE_INSTALL exists and is not empty
    then
        install_path="$WERCKER_BUNDLE_INSTALL_PATH"
    else
        install_path="$default_cache_path"
    fi
    bundle_command="$bundle_command --path $install_path"
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

if [ -n "$WERCKER_BUNDLE_INSTALL_GEMFILE" ] ; then
    gemfile_name="$WERCKER_BUNDLE_INSTALL_GEMFILE"
    bundle_command="$bundle_command --gemfile $gemfile_name"
fi

if [ -z "$WERCKER_BUNDLE_INSTALL_RETRY" ] ; then
    bundle_command="$bundle_command --retry 3"
else
    bundle_command="$bundle_command --retry $WERCKER_BUNDLE_INSTALL_RETRY"
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

retry() {

    try=$((try+1))

    if [ "$try" -gt "$MAX_TRIES" ]; then
        fail "Retry exceeds max retries";
    fi

    if [ "$WERCKER_BUNDLE_INSTALL_CLEAR_PATH" = "true" ]; then
        clear_install_path;
    else
        info "Skipping clearing path; WERCKER_BUNDLE_INSTALL_CLEAR_PATH is not set to true";
    fi

    info "Retrying bundle install, try: $try";
    exec_bundle_install;
}

clear_install_path() {
    if [ -n "$install_path" ]; then
        info "Clearing path: $install_path"
        rm -rf "$install_path";
    else
        warn "install_path not set, unable to clear install path";
    fi
}

exec_bundle_install() {
    debug "$bundle_command";
    $bundle_command;

    if [[ $? -ne 0 ]]; then
        info "Unable to execute bundle install";
        retry
    else
        info "bundle install completed succesfully"

        if ! type rbenv &> /dev/null ; then
            debug 'skipping rbenv rehash because rbenv is not found';
        else
            debug 'rbenv is found... will rehash';
            debug 'rbenv rehash';
            rbenv rehash;
            info 'rbenv rehash completed';
        fi
    fi
}

if [ ! -e "$PWD/$gemfile_name" ]; then
    info "Skipping bundle install because Gemfile not found in $PWD";
else
    info 'Gemfile found. Start bundle install.';

    install_bundler;
    exec_bundle_install;
fi
