require 'date'

# Проверка входных данных
if ARGV.size != 4
  puts "Неправильный формат ввода. Введите данные в виде: ruby build_calendar.rb teams.txt ДД.ММ.ГГГГ ДД.ММ.ГГГГ calendar.txt"
  exit 1
end

teams_file, start_str, end_str, output_file = ARGV

unless File.exist?(teams_file)
  puts "Файл #{teams_file} не найден"
  exit 1
end

# Парсинг дат
begin
  start_date = Date.parse(start_str, '%d.%m.%Y')
  end_date = Date.parse(end_str, '%d.%m.%Y')
rescue
  puts "Неправильный формат дат. Введите их в формате: ДД.ММ.ГГГГ"
  exit 1
end

if start_date >= end_date
  exit 1 
end

# Парсинг команд
teams = []
File.readlines(teams_file, encoding: 'UTF-8').each do |line|
  line = line.strip
  if line.empty?
    next
  end
  if line.include?(' — ')
    name, city = line.split(' — ', 2).map(&:strip)
    name = name.split('. ', 2)[1]
    teams << {name: name, city: city}
  end
end

if teams.size < 2
  puts "Необходимо минимум 2 команды"
  exit 1
end

# Создание всех возможных комбинаций пар
matches = []
teams.combination(2).each do |t1, t2|
  matches << {t1: t1[:name], t2: t2[:name], c1: t1[:city], c2: t2[:city]}
end

# Выбор пятниц, суббот и воскресений
play_days = []
(start_date..end_date).each do |d|
  play_days << d if [5, 6, 0].include?(d.wday)
end

times = ['12:00', '15:00', '18:00']

# Составление расписания
schedule = []
matches_cur = matches.dup 

play_days.each do |date|
  games_today = []
  
  times.each do |time|
    break if games_today.size >= 2 || matches_cur.empty?
    match = matches_cur.shift
    games_today << {time: time, **match}
  end
  
  schedule << {date: date, games: games_today} if games_today.any?
  break if matches_cur.empty?  
end

unless matches_cur.empty?
  puts "Не хватило дней для #{matches_cur.size} матчей"
else
  puts "Матчи распределены. Игровых дней: #{schedule.size}"
end

# Сохранение в файл
File.open(output_file, 'w:UTF-8') do |f|
  f.puts "Календарь турнира"
  f.puts "#{start_date.strftime('%d.%m.%Y')} - #{end_date.strftime('%d.%m.%Y')}"
  f.puts "Количество команд: #{teams.size}"
  f.puts "Количество матчей: #{matches.size}"
  f.puts "\n"
  
  schedule.each do |day|
    weekdays = ['Вс', 'Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб']
    f.puts "\n#{weekdays[day[:date].wday]}, #{day[:date].strftime('%d.%m.%Y')}:"
    
    day[:games].each do |g|
      f.puts "  #{g[:time]}  #{g[:t1]} (#{g[:c1]}) - #{g[:t2]} (#{g[:c2]})"
    end
  end
end

puts "Календарь составлен в файл #{output_file}"
