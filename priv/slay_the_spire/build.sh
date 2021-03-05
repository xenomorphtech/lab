#!/usr/bin/env elixir

md5sum = "6661e72999ce8b0e2b6f62809e8b2737"
jar = "6661e72999ce8b0e2b6f62809e8b2737.jar"
patched_jar = "6661e72999ce8b0e2b6f62809e8b2737-patched.jar"
original_dir = "#{md5sum}-original"
target_dir = "#{md5sum}"
true = File.exists?(jar)

if !File.exists?(original_dir) do
    IO.inspect "Decompiling #{jar}"
    res = :os.cmd('java -jar cfr-0.151.jar #{jar} --outputdir #{original_dir}')
    IO.puts res
    true = File.exists?(original_dir)

    File.cp_r!(original_dir, target_dir)
    File.cp!(jar, patched_jar)
    :os.cmd('chmod 0666 #{patched_jar}')
end

changed_files = :os.cmd('git diff --no-index --name-only #{original_dir} #{target_dir}')
|> :unicode.characters_to_binary()
|> String.split("\n")
|> Enum.filter(& String.ends_with?(&1, ".java"))
|> Enum.filter(& &1 != "")

if changed_files != [] do
    changed_files_str = Enum.join(changed_files, " ")
    res = :os.cmd('javac -classpath #{patched_jar} #{changed_files_str}')
    IO.puts res
    false = String.contains?("#{res}", "error")

    #copy files into a com/ folder, for injection into the jar
    File.rm_rf("com/")
    Enum.each(changed_files, fn(file)->
        workdir = Path.dirname(String.replace(file, "#{md5sum}/com/", "com/")) <> "/"
        File.mkdir_p!(workdir)

        class_file = String.replace(file, ".java", ".class")
        File.cp!(class_file, workdir<>Path.basename(class_file))
        #class_files = Path.wildcard(Path.dirname(file)<>"/"<>"*.class")
        #Enum.each(class_files, fn(class_file)->
        #    File.cp!(class_file, workdir<>Path.basename(class_file))
        #end)
    end)

    #zip up our jar
    res = :os.cmd('zip -ur #{patched_jar} com/')
    IO.puts res
    true = "#{res}" =~ "updating: "
end



