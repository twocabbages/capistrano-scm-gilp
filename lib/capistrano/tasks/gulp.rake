def gulp_zip(gulpfile, include_files)
  File.open(gulpfile, "a+") do |file|
    while line = file.gets
      "do find a replace"
    end
    output = File.open(gulpfile, "w")
    output << <<-FOO
// a gulp task to clean up vendor folder files for production machine.
var argv = require('yargs').argv;
var gulp = require('gulp');
var zip = require('gulp-zip');

var paths = __dirname;
var archive_name = argv.o ? argv.o : "archive.zip";
gulp.task('zip-vendor', function () {
    return gulp.src(
        [
            \"#{include_files.join("\",\n\"")}\"
            // if you thing there is more let me know.
        ],
        {base: '.'}
        )
        .pipe(zip(archive_name))
        .pipe(gulp.dest(paths));
})
    FOO
    output.close
  end
  sh "if command -v npm >/dev/null 2>&1; then echo >&2 \"npm is installed\"; else echo >&2 \"I require npm but it's not installed.  Aborting.\"; exit 1; fi"
  sh "if command -v gulp >/dev/null 2>&1; then echo 'gulp is installed';else npm install gulp;fi"
  sh "if npm list|grep gulp-zip > /dev/null 2>&1; then echo 'gulp-zip is installed';else npm install gulp-zip;fi"
  sh "if npm list|grep yargs > /dev/null 2>&1; then echo 'yargs is installed';else npm install yargs;fi"
  sh "gulp zip-vendor"
end

namespace :gulp do

  archive_name = "archive.zip"
  include_dir = fetch(:include_dir) || "*"
  exclude_files = fetch(:exclude_files) || []
  include_files = [
      "!**/._.DS_Store",
      "!**/.DS_Store",
      '!.DS_Store',
      '!.DS_Store/**',
      '!**/*.zip',
      '!**/.svn',
      '!**/.svn/**',
      '!**/.idea',
      '!**/.idea/**',
      '!frontend/runtime/debug/**',
      '!frontend/runtime/logs/**',
      '!backend/runtime/debug/**',
      '!backend/runtime/logs/**',
      '!attachment/**',
      '!assets/**',
      '!vendor/**/*.md',
      '!vendor/**/*.txt',
      '!vendor/**/*.pdf',
      '!vendor/**/LICENSE',
      '!vendor/**/CHANGES',
      '!vendor/**/README',
      '!vendor/**/VERSION',
      '!vendor/**/composer.json',
      '!vendor/**/.gitignore',
      '!vendor/**/docs',
      '!vendor/**/docs/**',
      '!vendor/**/tests',
      '!vendor/**/tests/**',
      '!vendor/**/unitTests',
      '!vendor/**/unitTests/**',
      '!vendor/**/.git',
      '!vendor/**/.git/**',
      '!vendor/**/.svn',
      '!vendor/**/.svn/**',
      '!vendor/**/examples',
      '!vendor/**/examples/**',
      '!vendor/**/build.xml',
      '!vendor/**/phpunit.xml',
      '!vendor/**/phpunit.xml.dist'
  ]

  desc "Archive files to #{archive_name}"
  task :zip_archive do

    gulpfile = "gulpfile.js"

    include_files = [
        '.*',
        '*.*',
        '**/*',
    ] + include_files + exclude_files

    gulp_zip(gulpfile, include_files)
  end

  desc "Vendor to #{archive_name}"
  task :zip_vendor do
    gulpfile = "gulpfile.js"
    include_files = [
        'vendor',
        'vendor/**/*',
    ] + include_files
    gulp_zip(gulpfile, include_files)
  end

  desc "Package project"
  task :package_project do
    gulpfile = "gulpfile.js"
    include_files = [
        '.*',
        '*.*',
        '**/*',
    ] + include_files
    gulp_zip(gulpfile, include_files)
  end

  desc "Deploy #{archive_name} to release_path"
  task :deploy do
    Rake::Task["gulp:zip_archive"].invoke

    tarball = archive_name
    on roles :all do

      # Make sure the release directory exists
      execute :mkdir, "-p", release_path

      # Create a temporary file on the server
      tmp_file = capture("mktemp")

      # Upload the archive, extract it and finally remove the tmp_file
      upload!(tarball, tmp_file)
      execute :unzip, "-o", tmp_file, "-d", release_path
      execute :rm, tmp_file
    end

    Rake::Task["gulp:clean"].invoke
  end

  desc "Deploy vendor to release_path"
  task :deploy_vendor do
    Rake::Task["gulp:zip_vendor"].invoke

    tarball = archive_name
    on roles :all do

      # Make sure the release directory exists
      execute :mkdir, "-p", shared_path

      # Create a temporary file on the server
      tmp_file = capture("mktemp")

      # Upload the archive, extract it and finally remove the tmp_file
      upload!(tarball, tmp_file)
      execute :unzip, "-o", tmp_file, "-d", shared_path
      execute :rm, tmp_file
    end

    Rake::Task["gulp:clean"].invoke
  end


  task :clean do |t|
    # Delete the local archive
    File.delete archive_name if File.exists? archive_name
  end

  task :create_release => :deploy

  task :check

  task :set_current_revision

end