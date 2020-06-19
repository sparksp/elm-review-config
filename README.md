# Shared elm-review config

![Build](https://github.com/sparksp/elm-review-config/workflows/Build/badge.svg)
![elm-review 2.0](https://img.shields.io/badge/elm--review-2.0-%231293D8)
![elm 0.19](https://img.shields.io/badge/elm-0.19-%231293D8)

I like all of my projects to follow the same rules so I've created a single repository that I reuse in my projects.

For unpublished rules copied from somewhere else I have extracted them in to `src/Vendor/` and also included a git submodule in `vendor/`.  The submodule helps me to keep track of any upstream changes and also keeps a full reference to the source, including any license they may have.


## Here be dragons!

These are the rules that I like to follow - you might not like them. If you like to have different rules per-project then this approach is not for you! You could use this as a template instead to get your review up and running quickly.


## Use this as a standalone config

1. Clone this config somewhere:
    ```
    $ git clone git@github.com:sparksp/elm-review-config.git
    ```

2. From your project, run elm-review with this config:
    ```
    $ elm-review --config /path/to/elm-review-config
    ```


## To add this to a project (as a submodule)

1. Make a branch to keep your project safe from any unexpected problems:
    ```
    $ git checkout -b shared-review-config master
    ```

2. Remove any existing `review/` folder:
    ```
    $ git rm -r review

    $ rm -r review
    ```

3. Add `elm-review-config` as a submodule:
    ```
    $ git submodule add -b master git@github.com:sparksp/elm-review-config.git review

    $ git submodule update --init --recursive review
    ```
    **Note:** I've used the SSH path here - this may cause deploy issues when cloning the repo in which case you can use the HTTPS path instead.

4. Check everything is working from the main repo:
    ```
    $ elm-review
    I found no problems while reviewing!
    ```

5. Commit your changes, you're good to go!
    ```
    $ git add review/
    $ git commit -m "Use shared review config"
    ```
