# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)
profiles = Profile.create([
  { first_name: "Carly",   gender: "female", birth_year: 1954, last_name: "Fiorina", },
  { first_name: "Donald",  gender: "male",   birth_year: 1946, last_name: "Trump",   },
  { first_name: "Ben",     gender: "male",   birth_year: 1951, last_name: "Carson",  },
  { first_name: "Hillary", gender: "female", birth_year: 1947, last_name: "Clinton", },
])

due_date = 1.year.since(Date.current)

profiles.each do |profile|
  profile.create_user(username: profile.last_name)
  list = TodoList.create(user: profile.user, list_due_date: due_date)
  5.times do |n|
    TodoItem.create(
      title: "item #{n}",
      description: "Description for item #{n}",
      todo_list: list,
      due_date: due_date
    )
  end
end
