#!/usr/bin/env perl

use strict;
use warnings;
use feature qw(say);
use Data::Dumper;

sub run {
    my ($memory) = @_;

    my $instruction_pointer = 0;
    say "Memory[225]: " .  $memory->[225];
    while (1) {
        my $instruction = get_instruction($memory, $instruction_pointer);
        my $halt = apply_instruction($memory, $instruction);
        last if $halt;
        $instruction_pointer += $instruction->{size};
    }

    return $memory->[0]
}
sub get_instruction {
    my ($memory, $instruction_pointer) = @_;
    my $instruction_size = {
        1 => 4,
        2 => 4,
        3 => 2,
        4 => 2,
        99 => 1,
    };
    my $mode_opcode = $memory->[$instruction_pointer];
    my $i = {};

    $i->{opcode} = $mode_opcode % 100;
    $i->{size} = $instruction_size->{$i->{opcode}}
	or die 'unknown opcode' . $i->{opcode};
    say join ',', @{$memory}[$instruction_pointer .. $instruction_pointer + $i->{size} - 1];
    my $mode = ($mode_opcode - $i->{opcode}) / 100;
    $i->{mode} = [ reverse(split(//, $mode)) ] if $mode;
    push @{$i->{mode}}, ((0) x ($i->{size} - @{$i->{mode}} - 1));

    my $params_start = $instruction_pointer + 1;
    my $params_end = $instruction_pointer + $i->{size} - 1;

    $i->{params} = [ @{$memory}[$params_start .. $params_end] ]
	if $i->{size} > 1;
    # print Dumper $i;
    return $i
}

sub add {
    my ($memory, $instruction) = @_;
    my $a = $instruction->{params}[0];
    $a = $memory->[$a] if ! $instruction->{mode}[0];
    my $b = $instruction->{params}[1];
    $b = $memory->[$b] if ! $instruction->{mode}[1];

    my $c = $instruction->{params}[2];
    $memory->[$c] = $a + $b;
    return
}

sub mul {
    my ($memory, $instruction) = @_;
    my $a = $instruction->{params}[0];
    $a = $memory->[$a] if ! $instruction->{mode}[0];
    my $b = $instruction->{params}[1];
    $b = $memory->[$b] if ! $instruction->{mode}[1];

    my $c = $instruction->{params}[2];
    $memory->[$c] = $a * $b;
    return
}

sub input {
    my ($memory, $instruction) = @_;
    my $a = $instruction->{params}[0];
    my $in = <STDIN>;
    chomp $in;
    $memory->[$a] = $in;
    return
}

sub output {
    my ($memory, $instruction) = @_;
    my $a = $instruction->{params}[0];
    $a = $memory->[$a] if ! $instruction->{mode}[0];
    say "OUT: " . $a;
    return
}

sub halt {
    return 1
}

sub apply_instruction {
    my ($memory, $instruction) = @_;
    my $ops = {
        1 => \&add,
        2 => \&mul,
	3 => \&input,
	4 => \&output,
        99 => \&halt,
    };
    return $ops->{$instruction->{opcode}}->($memory, $instruction)
}

my $program = <DATA>;
chomp $program;

my $memory = [ split /,/, $program ];

run($memory);


__DATA__
3,225,1,225,6,6,1100,1,238,225,104,0,1002,148,28,224,1001,224,-672,224,4,224,1002,223,8,223,101,3,224,224,1,224,223,223,1102,8,21,225,1102,13,10,225,1102,21,10,225,1102,6,14,225,1102,94,17,225,1,40,173,224,1001,224,-90,224,4,224,102,8,223,223,1001,224,4,224,1,224,223,223,2,35,44,224,101,-80,224,224,4,224,102,8,223,223,101,6,224,224,1,223,224,223,1101,26,94,224,101,-120,224,224,4,224,102,8,223,223,1001,224,7,224,1,224,223,223,1001,52,70,224,101,-87,224,224,4,224,1002,223,8,223,1001,224,2,224,1,223,224,223,1101,16,92,225,1101,59,24,225,102,83,48,224,101,-1162,224,224,4,224,102,8,223,223,101,4,224,224,1,223,224,223,1101,80,10,225,101,5,143,224,1001,224,-21,224,4,224,1002,223,8,223,1001,224,6,224,1,223,224,223,1102,94,67,224,101,-6298,224,224,4,224,102,8,223,223,1001,224,3,224,1,224,223,223,4,223,99,0,0,0,677,0,0,0,0,0,0,0,0,0,0,0,1105,0,99999,1105,227,247,1105,1,99999,1005,227,99999,1005,0,256,1105,1,99999,1106,227,99999,1106,0,265,1105,1,99999,1006,0,99999,1006,227,274,1105,1,99999,1105,1,280,1105,1,99999,1,225,225,225,1101,294,0,0,105,1,0,1105,1,99999,1106,0,300,1105,1,99999,1,225,225,225,1101,314,0,0,106,0,0,1105,1,99999,108,677,677,224,102,2,223,223,1005,224,329,101,1,223,223,1107,677,226,224,102,2,223,223,1006,224,344,101,1,223,223,1107,226,226,224,102,2,223,223,1006,224,359,101,1,223,223,1108,677,677,224,102,2,223,223,1005,224,374,101,1,223,223,8,677,226,224,1002,223,2,223,1005,224,389,101,1,223,223,108,226,677,224,1002,223,2,223,1006,224,404,1001,223,1,223,107,677,677,224,102,2,223,223,1006,224,419,101,1,223,223,1007,226,226,224,102,2,223,223,1005,224,434,101,1,223,223,1007,677,677,224,102,2,223,223,1005,224,449,1001,223,1,223,8,677,677,224,1002,223,2,223,1006,224,464,101,1,223,223,1108,677,226,224,1002,223,2,223,1005,224,479,101,1,223,223,7,677,226,224,1002,223,2,223,1005,224,494,101,1,223,223,1008,677,677,224,1002,223,2,223,1006,224,509,1001,223,1,223,1007,226,677,224,1002,223,2,223,1006,224,524,1001,223,1,223,107,226,226,224,1002,223,2,223,1006,224,539,1001,223,1,223,1107,226,677,224,102,2,223,223,1005,224,554,101,1,223,223,1108,226,677,224,102,2,223,223,1006,224,569,101,1,223,223,108,226,226,224,1002,223,2,223,1006,224,584,1001,223,1,223,7,226,226,224,1002,223,2,223,1006,224,599,101,1,223,223,8,226,677,224,102,2,223,223,1005,224,614,101,1,223,223,7,226,677,224,1002,223,2,223,1005,224,629,101,1,223,223,1008,226,677,224,1002,223,2,223,1006,224,644,101,1,223,223,107,226,677,224,1002,223,2,223,1005,224,659,1001,223,1,223,1008,226,226,224,1002,223,2,223,1006,224,674,1001,223,1,223,4,223,99,226

1002,4,3,4,33

1,9,10,3,2,3,11,0,99,30,40,50

1,0,0,3,1,1,2,3,1,3,4,3,1,5,0,3,2,10,1,19,1,19,9,23,1,23,6,27,1,9,27,31,1,31,10,35,2,13,35,39,1,39,10,43,1,43,9,47,1,47,13,51,1,51,13,55,2,55,6,59,1,59,5,63,2,10,63,67,1,67,9,71,1,71,13,75,1,6,75,79,1,10,79,83,2,9,83,87,1,87,5,91,2,91,9,95,1,6,95,99,1,99,5,103,2,103,10,107,1,107,6,111,2,9,111,115,2,9,115,119,2,13,119,123,1,123,9,127,1,5,127,131,1,131,2,135,1,135,6,0,99,2,0,14,0
