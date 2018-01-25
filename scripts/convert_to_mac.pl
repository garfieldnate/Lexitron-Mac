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
my $src_name;
my $trg;
my $trg_name;
my $tag_names;
my $id_prefix;
if ($ARGV[0] eq 'en-th') {
    $src = 'en';
    $src_name = 'English';
    $trg = 'th';
    $trg_name = 'Thai';
    $tag_names = get_tag_names('e', 't');
    $id_prefix = 'etlex-';
} elsif ($ARGV[0] eq 'th-en') {
    $src = 'th';
    $src_name = 'Thai';
    $trg = 'en';
    $trg_name = 'English';
    $tag_names = get_tag_names('t', 'e');
    $id_prefix = 'telex-';
} else {
    die $USAGE;
}

my %sequences;
my $twig = new XML::Twig(
    map_xmlns => {'http://www.w3.org/1999/xhtml' => '', 'http://www.apple.com/DTDs/DictionaryService-1.0.rng' => 'd'},
    start_tag_handlers => { dic => \&root },
    twig_handlers => { Doc => \&entry, dic => \&root_finished },
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
    my ( $twig, $root ) = @_;
    $root->set_name('d:dictionary');
    $root->set_atts({
        xmlns => 'http://www.w3.org/1999/xhtml',
        'xmlns:d' => 'http://www.apple.com/DTDs/DictionaryService-1.0.rng'});
}

sub root_finished {
    my ( $twig, $root ) = @_;
    # Paste new entries for each group of sequenced headwords
    for my $head_word (keys %sequences) {
        my $entry = XML::Twig::Elt->new('d:entry',
            {'d:title' => $head_word, lang => $src});
        my $id = join ',', map {$_->id} @{$sequences{$head_word}};
        $entry->set_att(id => $id);
        $entry->paste('last_child', $root);

        my $index = XML::Twig::Elt->new('d:index', {'d:value' => $head_word});
        $index->paste('last_child', $entry);

        for my $div (@{$sequences{$head_word}}) {
            $div->paste('last_child', $entry);
        }
    }
}

sub entry {
    my ( $twig, $el ) = @_;

    my $id = $el->first_child('id');
    die 'no id' unless $id;
    $id->delete;
    my $id_text = $id_prefix . $id->text;

    my $head_word = $el->first_child($tag_names->{head_word});
    die 'no head_word' unless $head_word;
    my $head_word_text = $head_word->text;
    $head_word->delete;

    my $search = $el->first_child($tag_names->{search});
    my $search_text;
    if ($search) {
        $search_text = $search->text;
        $search->delete;
    } else {
        $search_text = $head_word_text;
    }

    my $cat = $el->first_child($tag_names->{cat});
    my $trans = $el->first_child($tag_names->{trans});
    my $src_syns = $el->first_child($tag_names->{syn});
    my $trg_syns = $el->first_child($tag_names->{similar});
    my $ants = $el->first_child($tag_names->{ant});
    my $def = $el->first_child($tag_names->{def});
    my $sample = $el->first_child($tag_names->{sample});
    my $notes = $el->first_child($tag_names->{notes});
    my $num = $el->first_child($tag_names->{num});

    # Next: These numbered entries need to be placed all in one entry with rangey ID
    my $sequence_number;
    # extra numbers tacked onto the end of the headword means it's a numbered entry (7 is highest, so only match one digit in case we get something stupid like "Vitamin B123")
    if ($head_word_text ne $search_text && $head_word_text =~ m/(\d)$/) {
        $head_word_text = $search->text;
        $sequence_number = $1;
    }

    my $header = get_header($head_word_text, $sequence_number);

    # d:entry element will be created later from combined div's if this is part of a sequence of entries
    $el->set_name('div');
    $el->set_att(class => 'entry-container');
    $el->set_att(lang => $src);
    $header->paste('first_child', $el);
    if (!$sequence_number) {
        my $entry_wrapper = $el->wrap_in('d:entry' => {'d:title' => $head_word->text, id => $id_text});
        my $index = XML::Twig::Elt->new('d:index', {'d:value' => $search_text, class => 'index'});
        $index->paste('first_child', $entry_wrapper);
    } else {
        $el->set_att(id => $id_text);
    }

    if($cat) {
        $cat->set_name('small');
        $cat->set_att('class', 'category');
        $cat->move('after', $header);
    }
    if($num) {
        $num->set_name('small');
        $num->set_att('class', 'classifier');
        if($cat) {
            $num->move('after', $cat);
        } else {
            $num->move('after', $header);
        }
    }
    # Next: turn all p elements into divs containing p elements and headers
    if($trans) {
        $trans->set_name('p');
        $trans->set_atts({class => 'translation', lang => $trg});
        $trans->move('last_child', $el);
        XML::Twig::Elt->new("span", {class => 'trans-label'}, 'Translation: ')->paste('first_child', $trans);
    }
    if($def) {
        $def->set_name('p');
        $def->set_atts({class => 'definition'});
        $def->move('last_child', $el);
        XML::Twig::Elt->new("span", {class => 'definition-label'}, 'Definition: ')->paste('first_child', $def);
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
        XML::Twig::Elt->new("span", {class => 'notes-label'}, 'Notes: ')->paste('first_child', $notes);
    }

    if($src_syns) {
        my @synonyms = split /[;,]\s*/, $src_syns->text;
        my $div = XML::Twig::Elt->new('div', {class => 'source-synonyms'});
        XML::Twig::Elt->new("h4", {class => 'syns-header'}, "$src_name Synonyms")->paste('first_child', $div);
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
        my @synonyms = split /[;,]\s*/, $trg_syns->text;
        my $div = XML::Twig::Elt->new('div', {class => 'target-synonyms', lang => $trg});
        XML::Twig::Elt->new("h4", {class => 'syns-header'}, "$trg_name Synonyms")->paste('first_child', $div);
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
        my @antonyms = split /[;,]\s*/, $ants->text;
        my $div = XML::Twig::Elt->new('div', {class => 'antonyms'});
        XML::Twig::Elt->new("h4", {class => 'ants-header'}, 'Antonyms')->paste('first_child', $div);
        $div->paste('last_child', $el);
        my $list = XML::Twig::Elt->new('ul');
        $list->paste('last_child', $div);
        for my $ant (@antonyms) {
            my $li = XML::Twig::Elt->new('li', $ant);
            $li->paste('last_child', $list);
        }
        $ants->delete;
    }

    if($sequence_number) {
        $el->cut;
        push @{$sequences{$head_word_text}}, $el;
    } else {
        $el->flush;
    }
}

sub get_header {
    my ($head_word_text, $sequence_number) = @_;
    my $header = XML::Twig::Elt->new('h2', {class => 'header'}, $head_word_text);
    if ($sequence_number) {
        XML::Twig::Elt->new('sup', {class => 'sequence-number'}, "$sequence_number")->paste('last_child', $header);
    }
    return $header;
}
