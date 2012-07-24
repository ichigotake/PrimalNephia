use inc::Module::Install;
name 'Nephia';
all_from 'lib/Nephia.pm';

requires 'Exporter';
requires 'Plack';
requires 'JSON';
requires 'Text::Xslate';

requires 'Path::Class' => 0.26;
requires 'Cwd';
requires 'File::Spec';
requires 'String::CamelCase';

tests 't/*.t';
author_tests 'xt';

test_requires 'Test::More';

install_script 'bin/nephia-setup';

auto_set_repository;
auto_include;
WriteAll;
