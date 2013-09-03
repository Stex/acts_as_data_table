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
