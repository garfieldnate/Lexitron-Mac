#!/usr/env perl
# Convert the etlex/telex XML into Mac dictionary XML
use strict;
use warnings;
use XML::Twig;

binmode STDOUT, ':utf8';
$|++;

my $USAGE = "Usage: convert_to_mac.pl <th-en|en-th> <LEXiTRON file>";

if ( @ARGV < 2 ) {
    die $USAGE;
}

my $src;
my $trg;
my $tag_names;
my $id_prefix;
if ($ARGV[0] eq 'en-th') {
    $src = 'en';
    $trg = 'th';
    $tag_names = get_tag_names('e', 't');
    $id_prefix = 'etlex-';
} elsif ($ARGV[0] eq 'th-en') {
    $src = 'th';
    $trg = 'en';
    $tag_names = get_tag_names('t', 'e');
    $id_prefix = 'telex-';
} else {
    die $USAGE;
}

my $twig = new XML::Twig(
    map_xmlns => {'http://www.w3.org/1999/xhtml' => '', 'http://www.apple.com/DTDs/DictionaryService-1.0.rng' => 'd'},
    start_tag_handlers => { dic => \&root },
    twig_handlers => { Doc => \&entry },
    pretty_print => 'indented',
    keep_original_prefix => 1,
    empty_tags => 'html',
);

$twig->parsefile( $ARGV[1] );
$twig->flush;

sub get_tag_names {
    my ($src_prefix, $trg_prefix) = @_;
    return {
        head_word => $src_prefix . 'entry',
        trans => $trg_prefix . 'entry',
        search => $src_prefix . 'search',
        cat => $src_prefix . 'cat',
        syn => $src_prefix . 'syn',
        ant => $src_prefix . 'ant',
        similar => ($src_prefix eq 'e' ? 'ethai' : 'tenglish'),
        notes => ($src_prefix eq 't' ? 'notes' : 'x'),
        def => ($src_prefix eq 't' ? 'tdef' : 'x'),
        num => ($src_prefix eq 't' ? 'tnum' : 'x'),
        sample => ($src_prefix eq 't' ? 'tsample' : 'x'),
    };
}

sub root {
    my ( $twig, $el ) = @_;
    $el->set_name('d:dictionary');
    $el->set_atts({
        xmlns => 'http://www.w3.org/1999/xhtml',
        'xmlns:d' => 'http://www.apple.com/DTDs/DictionaryService-1.0.rng'});
}

sub entry {
    my ( $twig, $el ) = @_;

    my $id = $el->first_child('id');
    die 'no id' unless $id;
    my $search = $el->first_child($tag_names->{search});
    my $head_word = $el->first_child($tag_names->{head_word});
    die 'no head_word' unless $head_word;
    my $cat = $el->first_child($tag_names->{cat});
    my $trans = $el->first_child($tag_names->{trans});
    my $src_syns = $el->first_child($tag_names->{syn});
    my $trg_syns = $el->first_child($tag_names->{similar});
    my $ants = $el->first_child($tag_names->{ant});

    my $def = $el->first_child($tag_names->{def});
    my $sample = $el->first_child($tag_names->{sample});
    my $notes = $el->first_child($tag_names->{notes});
    my $num = $el->first_child($tag_names->{num});

    $el->set_name('d:entry');
    $el->set_atts({
        id => $id_prefix . $id->text,
        'd:title' => $head_word->text,
        lang => $src});
    $id->delete;

    my $search_text;
    if($search) {
        $search_text = $search->text;
        $search->delete;
    } else {
        $search_text = $head_word->text;
    }
    my $index = XML::Twig::Elt->new('d:index', {'d:value' => $search_text, class => 'index'});
    $index->paste('first_child', $el);

    my $header = XML::Twig::Elt->new('h1', {class => 'header'}, $head_word->text);
    $header->paste('after', $index);
    $head_word->delete;

    if($cat) {
        $cat->set_name('small');
        $cat->set_att('class', 'category');
        $cat->move('before', $header);
    }
    if($num) {
        $num->set_name('small');
        $num->set_att('class', 'classifier');
        $num->move('before', $header);
    }
    if($trans) {
        $trans->set_name('p');
        $trans->set_atts({class => 'translation', lang => $trg});
        $trans->move('last_child', $el);
        XML::Twig::Elt->new("span", {class => 'trans-label'})->paste('first_child', $trans);
    }
    if($def) {
        $def->set_name('p');
        $def->set_atts({class => 'definition'});
        $def->move('last_child', $el);
        XML::Twig::Elt->new("span", {class => 'definition-label'})->paste('first_child', $def);
    }
    if($sample) {
        $sample->set_name('p');
        $sample->set_atts({class => 'sample'});
        $sample->move('last_child', $el);
        XML::Twig::Elt->new("span", {class => 'sample-label'}, 'Example: ')->paste('first_child', $sample);
    }
    if($notes) {
        $notes->set_name('p');
        $notes->set_atts({class => 'notes'});
        $notes->move('last_child', $el);
        XML::Twig::Elt->new("span", {class => 'notes-label'}, 'Notes:')->paste('first_child', $notes);
    }

    if($src_syns) {
        my @synonyms = split /;\s*/, $src_syns->text;
        my $div = XML::Twig::Elt->new('div', {class => 'source-synonyms'});
        $div->paste('last_child', $el);
        my $list = XML::Twig::Elt->new('ul');
        $list->paste('last_child', $div);
        for my $syn (@synonyms) {
            my $li = XML::Twig::Elt->new('li', $syn);
            $li->paste('last_child', $list);
        }
        $src_syns->delete;
    }
    if($trg_syns) {
        my @synonyms = split /;\s*/, $trg_syns->text;
        my $div = XML::Twig::Elt->new('div', {class => 'target-synonyms'});
        $div->paste('last_child', $el);
        my $list = XML::Twig::Elt->new('ul');
        $list->paste('last_child', $div);
        for my $syn (@synonyms) {
            my $li = XML::Twig::Elt->new('li', $syn);
            $li->paste('last_child', $list);
        }
        $trg_syns->delete;
    }
    if($ants) {
        my @antonyms = split /;\s*/, $ants->text;
        my $div = XML::Twig::Elt->new('div', {class => 'antonyms'});
        $div->paste('last_child', $el);
        my $list = XML::Twig::Elt->new('ul');
        $list->paste('last_child', $div);
        for my $ant (@antonyms) {
            my $li = XML::Twig::Elt->new('li', $ant);
            $li->paste('last_child', $list);
        }
        $ants->delete;
    }
    $el->flush;
}
