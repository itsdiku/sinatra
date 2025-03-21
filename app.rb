require 'sinatra'
require 'sqlite3'

# Connect to the SQLite3 database
DB = SQLite3::Database.new('todos.db')

# Create the items table if it doesn't exist
DB.execute(<<-SQL)
  CREATE TABLE IF NOT EXISTS items (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL
  );
SQL

# Homepage - Display all items
get '/' do
  @items = DB.execute('SELECT * FROM items')
  erb :index
end

# Add a new item
post '/add-item' do
  item = params[:item]

  # Insert the new item into the database
  DB.execute('INSERT INTO items (name) VALUES (?)', item)

  # Fetch the ID of the newly inserted item
  id = DB.last_insert_row_id

  # Return a Turbo Stream response to append the new item and reset the form
  content_type 'text/vnd.turbo-stream.html'
  <<-STREAM
  <turbo-stream action="append" target="items">
    <template>
      <li id="item-#{id}" class="list-group-item d-flex justify-content-between align-items-center">
        #{item}
        <form action="/delete-item/#{id}" method="post" style="display: inline;">
          <button type="submit" class="btn btn-danger btn-sm">Delete</button>
        </form>
      </li>
    </template>
  </turbo-stream>
  <turbo-stream action="replace" target="todo-form">
    <template>
      <form id="todo-form" action="/add-item" method="post" data-turbo="true" class="mb-3">
        <div class="input-group">
          <input type="text" name="item" placeholder="Enter a new item" class="form-control">
          <button type="submit" class="btn btn-primary">Add Item</button>
        </div>
      </form>
    </template>
  </turbo-stream>
  STREAM
end

# Delete an item
post '/delete-item/:id' do
  id = params[:id]

  # Delete the item from the database
  DB.execute('DELETE FROM items WHERE id = ?', id)

  # Return a Turbo Stream response to remove the item from the DOM
  content_type 'text/vnd.turbo-stream.html'
  <<-STREAM
  <turbo-stream action="remove" target="item-#{id}"></turbo-stream>
  STREAM
end
