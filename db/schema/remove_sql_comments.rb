lines = IO.readlines('annuaire.sql')
new_lines = []
lines.each do |l|
  if l.index('COMMENT =') != nil
    new_lines[-1] = new_lines[-1][0...-3] + ";\n"
  else
    new_lines.push(l)
  end
end

File.open('annuaire_no_comment.sql', 'w') do |f|  
  new_lines.each {|l| f.puts(l)}
end