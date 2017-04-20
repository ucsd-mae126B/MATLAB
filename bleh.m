clear all; close all; clc;
x = [0:.01:1]
f = x.^2
df = diff(f);
dx = diff(x);
fp = df./dx