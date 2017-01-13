# puppet-lint use_ensure_packages check

[![Build Status](https://travis-ci.org/ninech/puppet-lint-use_ensure_packages-check.svg?branch=master)](https://travis-ci.org/ninech/puppet-lint-use_ensure_packages-check)
[![Gem Version](https://badge.fury.io/rb/puppet-lint-use_ensure_packages-check.svg)](https://badge.fury.io/rb/puppet-lint-use_ensure_packages-check)

## Installation

To use this plugin, add the following like to the Gemfile in your Puppet code
base and run `bundle install`.

```ruby
gem 'puppet-lint-use_ensure_packages-check'
```

## Usage

This plugin provides a new check to `puppet-lint`.

### use_ensure_packages

**--fix support: yes**

This check will raise a error for constructs like the following.

```
  if ! defined(Package['foo']) {
    package { 'foo': }
  }
```

And offer you the option to rewrite it to use ensure_packages with the **--fix**
option. This would be transformed into the following.

```
  ensure_packages(['foo'])
```
