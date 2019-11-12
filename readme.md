Aspect Lua Template
===================

[![Build Status](https://travis-ci.org/unifire-app/aspect.svg?branch=master)](https://travis-ci.org/unifire-app/aspect)
[![Build status](https://ci.appveyor.com/api/projects/status/f5vlmegvs7fe2gjt?svg=true)](https://ci.appveyor.com/project/bzick/aspect)
[![codecov](https://codecov.io/gh/unifire-app/aspect/branch/master/graph/badge.svg)](https://codecov.io/gh/unifire-app/aspect)
[![Luarocks](https://img.shields.io/badge/LuaRocks-Aspect-blue)](https://luarocks.org/modules/unifire/aspect)


**Aspect** is a compiling templating engine for Lua and OpenResty.


The key-features are...
* _Well known_: The most popular Django-like syntax is used - 
  [Twig2](https://twig.symfony.com/doc/2.x/templates.html) compatible and [Jinja2](https://jinja.palletsprojects.com/en/2.10.x/templates/) like.
* _Fast_: Aspect compiles templates down to plain optimized Lua code. 
  Moreover, Lua cod compiles into bytecode - the fastest representation of a template.
* _Secure_: Aspect has a sandbox mode to evaluate all template code. 
  This allows Aspect to be used as a template language for applications where users may modify the template design.
* _Flexible_: Aspect is powered by a flexible lexer and parser. 
  This allows the developer to define their own custom tags, filters, functions and operators, and to create their own DSL.
* _Comfortable_: Aspect allows you to process userdata data. 
  More intuitive behavior with special values such as a empty string, number zero and so on.
* _Memory-safe_: The template is built in such a way as to save maximum memory when it is executed, 
  even if the iterator provides a lot of data.

Synopsis
--------

```twig
<!DOCTYPE html>
<html>
    <head>
        {% block head %}
            <title>{{ page.title }}</title>
        {% endblock %}
    </head>
    <body>
        {% block content %}
            <ul id="navigation">
            {% for item in navigation %}
                <li><a href="{{ item.href }}">{{ item.caption }}</a></li>
            {% endfor %}
            </ul>
    
            <h1>My Webpage</h1>
            {{ page.body }}
        {% endblock %}
    </body>
</html>
```

Aspect Documentation
--------------------

* [Installation](./docs/installation.md)
* [Basic Usage](./docs/api.md#basic-api-usage)
* [Configuration](./docs/api.md#options)
* [Cache](./docs/api.md#cache)

Syntax
------

* [Variables](./docs/syntax.md#variables)
* [Expression](./docs/syntax.md#expressions)
* [Filters](./docs/syntax.md#filters)
* [Functions](./docs/syntax.md#functions)
* [Named Arguments](./docs/syntax.md#named-arguments)
* [Control Structure](./docs/syntax.md#control-structure)
* [Comments](./docs/syntax.md#comments)
* [Template Inheritance](./docs/syntax.md#template-inheritance)
* [Macros](./docs/syntax.md#macros)
* [Expressions](./docs/syntax.md#expressions)
* [Operators](./docs/syntax.md#operators)

Tags
----

* [set](./docs/tags/set.md) — assign values to variables
* [do](./docs/tags/do.md) 
* [if, elseif, elif, else](./docs/tags/if.md) — conditional statement
* [for, else](./docs/tags/for.md) — loop over each item in a sequence.
* [macro](./docs/tags/macro.md), [import](./docs/tags/macro.md#importing-macros), [from](./docs/tags/macro.md#importing-macros)
* [include](./docs/tags/include.md) — includes a template and returns the rendered content
* [extends](./docs/tags/extends.md), [block](./docs/tags/extends.md#block), [use](./docs/tags/extends.md#use) — 
  template inheritance ([read more](./docs/syntax.md#template-inheritance))
* apply
* autoescape
* verbatim aka ignore

Filters
-------

* [abs](./docs/filters/abs.md)
* [batch(size)](./docs/filters/batch.md)
* [column(column)](./docs/filters/columns.md)
* [date(format)](./docs/filters/date.md)
* [date_modify(offset)](./docs/filters/date_modify.md)
* [escape(type), e(type)](./docs/filters/escape.md)
* [default(value, boolean)](./docs/filters/default.md)
* [first](./docs/filters/first.md)
* [last](./docs/filters/last.md)
* [format(...)](./docs/filters/format.md)
* format_number(opts)
* [join(delim, last_delim)](./docs/filters/join.md)
* [json_encode](./docs/filters/json_encode.md)
* [keys](./docs/filters/keys.md)
* [length](./docs/filters/length.md)
* [lower](./docs/filters/lower.md)
* [upper](./docs/filters/lower.md)
* merge(items)
* nl2br
* [raw](./docs/filters/raw.md)
* replace
* split(delim, count)
* striptags(tags)
* [trim](./docs/filters/trim.md)
* url_encode
* strip

Functions
---------

* [parent()](./docs/tags/extends.md#parent)
* [block(name, template)](./docs/tags/extends.md#block-function)
* [range(low, high, step)](./docs/funcs/range.md)
* [date(date)](./docs/funcs/date.md)
* [dump()](./docs/funcs/dump.md)

Tests
-----

* [is defined](./docs/tests/defined.md)
* [is odd](./docs/tests/odd.md)
* [is even](./docs/tests/even.md)
* [is iterator](./docs/tests/defined.md)
* [is empty](./docs/tests/empty.md)
* [is divisible by()](./docs/tests/divisible_by.md)
* [is null, is nil](./docs/tests/null.md)
* [is_same_as](./docs/tests/same_as.md)

Extending
---------

* [Add tags](./docs/api.md#add-tags)
* [Add filter](./docs/api.md#add-filters)
* [Add functions](./docs/api.md#add-functions)
* [Add tests](./docs/api.md#add-tests)
* [Add operators](./docs/api.md#add-operators)
* [Configure behaviors](./docs/api.md#behaviors)