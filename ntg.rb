#!/usr/bin/env ruby

# n
p = proc { |x, w, b| x * w + b }
e = proc { |x, w| x * w }
relu = proc { |x| x > 0 ? x : 0 }
rb = proc { rand(-5.0..5.0) }
rw = proc { rand(-50..50) }

# neuron -> activation (relu) -> edge
net = proc do |px, pw, pb, ex, ew, eb, ew1, ew2, ow1, ow2, ob1, ob2|
  ev = p.call(ex, ew, eb)
  pv = p.call(px, pw, pb)

  e1 = e.call(relu.call(ev), ew1)
  e2 = e.call(relu.call(pv), ew2)

  o1 = p.call(e1, ow1, ob1)
  o2 = p.call(e2, ow2, ob2)

  d = relu.call(o1 + o2)
  d > 0 ? :left : :right
end

# tg
require 'isna'

size = 32

player = { :char => 'P'.to_ansi.green.to_s, :x => 25 }
enemy  = { :char => 'E'.to_ansi.red.to_s, :x => (size - 1) }

world = proc {  size.times.map { ' ' } }

update_enemy = proc do |enemy|
  enemy[:x] += $ed
  enemy[:x] = (size - 1) if enemy[:x] < 0
  enemy[:x] = 0 if enemy[:x] > (size - 1)
end

move_player = proc do |player, direction|
  if direction == :left
    player[:x] -= 1
    player[:x] = (size - 1) if player[:x] < 0
  elsif direction == :right
    player[:x] += 1
    player[:x] = 0 if player[:x] > (size - 1)
  end
end

render = proc do |world, player, enemy|
  w = world.call
  w[player[:x]] = player[:char]
  w[enemy[:x]] = enemy[:char]
  w.join
end

collision = proc do |p, e|
  next true if p[:x] == e[:x]
  next true if p[:x] + 1 == e[:x]
  next true if p[:x] - 1 == e[:x]
  false
end

update_player = proc do |player, direction|
  move_player.call(player, direction)
end

brain = proc do
  ia = nil
  ib = rw.call
  ic = rb.call
  id = nil
  ie = rw.call
  ii = rb.call
  ig = rw.call
  ih = rw.call
  ii = rw.call
  ij = rw.call
  ik = rb.call
  il = rb.call

  proc { |px, ex|
    a = [px, ib, ic, (px - ex).abs, ie, ii, ig, ih, ii, ij, ik, il]
    [net.call(*a), a]
  }
end

enemy_direction = proc { rand < 0.5 ? -1 : 1 }

$running = true

shutdown = proc do
  # restore cursor
  print "\e[?25h"
  puts ''
  puts 'bye.'
  $running = false
  exit 0
end

trap('INT', &shutdown)
trap('TERM', &shutdown)
trap('QUIT', &shutdown)

Thread.new do
  loop do
    break unless $running
    # $ed = enemy_direction.call
    sleep 3
  end
end
Process.waitall

gen = 1
$brain = brain.call
$ed = enemy_direction.call
score = 0

update_game = proc do |player, enemy|
  direction, genome = $brain.call(player[:x], enemy[:x])
  pg = genome.map { |g| g.round(2) }
  update_player.call(player, direction)
  update_enemy.call(enemy)
  if collision.call(player, enemy)
    $brain = brain.call
    gen += 1
    score = 0
    player[:x] = (size / 2).round
    enemy[:x] = size
  end
  map = render.call(world, player, enemy)
  start = '['.to_ansi.yellow.to_s
  stop = ']'.to_ansi.yellow.to_s
  # puts "Dna: #{pg.join(', ')}"
  puts "Gen: #{gen}, Score: #{score}"
  puts "#{start}#{map}#{stop}"
end

puts "\e[?25l"
loop do
  break unless $running
  score += 1
  update_game.call(player, enemy, score)
  sleep 0.1
  puts "\e[H\e[2J" * 500
end
