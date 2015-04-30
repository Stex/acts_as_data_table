# ActsAsDataTable

This gem adds automatic filtering and sorting to models and controllers in Rails applications.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'acts_as_data_table'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install acts_as_data_table
    
The `sortable_columns` helper will also need a javascript file if you'd like to
use the `CTRL + Click` way of adding new sorting columns. 
You can easily generated it by using

    $ ruby script/generate acts_as_data_table js
    
Please note that this javascript addon requires jQuery.

## Usage

The gem consists of 3 parts:

1. Multi Column Queries, e.g. a full text search over several table columns
2. Automatic filtering based on (named) scopes defined in the model
3. Automatic sorting (`ORDER BY`) by multiple columns

### Multi Column Queries

TODO

### Scope Filters

TODO

### Sortable Columns

TODO

## Contributing

1. Fork it ( https://github.com/stex/acts_as_data_table/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
