use inc::Module::Install;
name 'Nephia';
all_from 'lib/Nephia.pm';

requires 'Exporter';
requires 'Plack';
requires 'JSON';
requires 'Text::Xslate';
requires 'Class::Load';

tests 't/*.t';
author_tests 'xt';

test_requires 'Test::More';
auto_set_repository;
auto_include;
WriteAll;
