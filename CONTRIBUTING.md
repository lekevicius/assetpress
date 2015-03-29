# Contributing

AssetPress currently has only been tested on a Mac. I would like it to support Windows, and will gladly accept pull requests that improve the compatibility.

All the code is written in CoffeeScript in src directory. Any contributions should try to keep the same code style.

There are no tests. That's no good. Although it's impossible to test the quality of generated images, I should write some tests for splitter, workflow and xcassets generator. PRs appreciated.

Finally, the code is generally synchronous. That works fairly well for a utility like this, however I plan to rewrite everything into asynchronous model in future releases.
