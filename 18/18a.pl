#!/usr/bin/env perl

use strict;
use warnings;
use Data::Dumper;
use feature qw(say);
use feature 'signatures';
no warnings 'experimental::signatures';

my ($map, $coords_of) = process_input([<>]);
# print Dumper $map;
# print Dumper $coords_of;
my %paths_from;
for my $object (keys %$coords_of) {
    $paths_from{$object} = paths_from($map, $coords_of, $object);
}

my %all_keys = map { ($_ => 1) } (grep { uc($_) ne $_ } (keys %paths_from));
say shortest_path(\%paths_from, '@', \%all_keys, {});

sub shortest_path($paths_from_ref, $current_position, $missing_keys, $cache) {
    my $cache_key = join '', (sort keys %$missing_keys), "-$current_position";
    if (exists $cache->{$cache_key}) {
        return $cache->{$cache_key}
    }

    delete $missing_keys->{$current_position};
    return 0 if ! keys %$missing_keys;
    my $current_options = $paths_from_ref->{$current_position};
    remove_door($paths_from_ref, uc $current_position);
    remove_door($paths_from_ref, $current_position);

    my @reachable_keys = sort {
             $current_options->{$a} <=> $current_options->{$b}
        } grep { uc($_) ne $_ } (keys %$current_options);
    return "inf" if !@reachable_keys;
    my $shortest_path = "inf";
    for my $key (@reachable_keys) {
        my %missing_keys = %$missing_keys;
        my $paths_from = clone_paths_from($paths_from_ref);
        my $path_length = $current_options->{$key}
            + shortest_path($paths_from, $key, \%missing_keys, $cache);
        
        $shortest_path = min($shortest_path, $path_length);
    }
    $cache->{$cache_key} = $shortest_path;
    return $shortest_path
}

sub sum {
    my $sum = 0;
    $sum += $_ // 0 for @_;
    return $sum
}

sub clone_paths_from($original) {
    my $clone = {};
    for my $k1 (keys %$original) {
        for my $k2 (keys %{$original->{$k1}}) {
            $clone->{$k1}{$k2} = $original->{$k1}{$k2};
        }
    }
    return $clone
}


sub remove_door($paths_from, $door) {
    my $paths_from_door = delete $paths_from->{$door};
    for my $object (keys %$paths_from) {
        next if ! exists $paths_from->{$object}{$door};
        for my $object_via_door (keys %$paths_from_door) {
            $paths_from->{$object}{$object_via_door} = min(
                $paths_from->{$object}{$object_via_door},
                $paths_from->{$object}{$door} + $paths_from_door->{$object_via_door}
            )
        }
        delete $paths_from->{$object}{$object};
        delete $paths_from->{$object}{$door};
    }
}

sub min($x, $y) {
    return $y if ! $x;
    return $x if ! $y;
    return $x if $x <= $y;
    return $y;
}

sub process_input($input) {
    my $map = [];
    my $coords_of = {};
    my $i = 0;
    for my $line (@$input) {
        my $j = 0;
        chomp $line;
        for my $object (split //, $line) {
            $coords_of->{$object} = [$i, $j] if $object !~ /[#.]/;
            $map->[$i][$j] = $object if $object !~ /[.]/;
            $map->[$i][$j] = '' if $object eq '.';
            $j++
        }
        $i++
    }
    return $map, $coords_of
}

sub paths_from($map, $coords_of, $object) {
    my ($x, $y) = @{ $coords_of->{$object} };
    my @neighbours = neighbours($map, $x, $y, 0);
    my %seen = ("$x,$y" => 1);
    my %paths;
    while (my $nb = shift @neighbours) {
        my ($nx, $ny, $distance, $nobject) = @$nb;
        next if $seen{"$nx,$ny"};
        $seen{"$nx,$ny"} = 1;
        $paths{$nobject} = $distance if $nobject;
        next if $nobject;
        push @neighbours, neighbours($map, $nx, $ny, $distance);
    }
    return \%paths
}

sub neighbours($map, $x, $y, $distance) {
    my @neighbours;
    for my $ncoords ([$x+1,$y], [$x-1,$y], [$x,$y+1], [$x,$y-1]) {
        my ($nx, $ny) = @$ncoords;
        my $object = $map->[$nx][$ny];
        next if $object eq '#';
        push @neighbours, [$nx, $ny, $distance+1, $object];
    }
    return @neighbours
}
