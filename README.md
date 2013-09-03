Acts As Data Table
==================

Multi column search, Column Sorting and Extended Filters for Rails Models

Installation
============

To install the plugin in a Rails 2.3.x application, simply run the following command:

    ruby script/plugin install https://github.com/Stex/acts_as_data_table.git
    
If you'd like to use the additional javascript functionality for multiple
sorting columns, you also have to run the javascript generator

    ruby script/generate acts_as_data_table js
    
which will copy the file `acts_as_data_table.js` to `/public/javascripts`.
Afterwards, you can simply include it to your application's layout using

    <%= javascript_include_tag 'acts_as_data_table' %>
    
Please note that this javascript addon requires jQuery.

Usage
=====

This section will provide some usage examples.

Multi column search
-------------------

To create a named scope which will automatically search for a string in multiple
columns of a a model and its associations, you can create it using

``` ruby
acts_as_searchable :column1, :column2, {options}
```
As an example, let's say we have a User and a Role model, where each user `has_many` roles. 
Now, to create a named scope which searches in the user's first and last name and his roles, 
this could be done by:

``` ruby
acts_as_searchable :first_name, :last_name, {:roles => :name}
```

However, this might lead to problems when a visitor enters the user's first and last name to the search field.
The plugin can automatically concat first and last name. The updated ruby line would be

``` ruby
acts_as_searchable [:first_name, :last_name], {:roles => :name}
```
