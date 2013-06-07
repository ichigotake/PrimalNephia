requires 'Class::Accessor::Fast';
requires 'Class::Accessor::Lite';
requires 'Config::Micro';
requires 'Cwd';
requires 'Encode';
requires 'Exporter';
requires 'File::Basename';
requires 'File::Spec';
requires 'JSON';
requires 'Path::Class', '0.26';
requires 'Plack';
requires 'Router::Simple';
requires 'Text::Xslate';

on build => sub {
    requires 'Test::More';
};
