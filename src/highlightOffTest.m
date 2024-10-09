x3ind = findstr('u[',estring);
x4ind = findstr('u [',estring);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% filter out those indices with an alphanumeric char just before the x in
%    x1ind
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

lownumbound = 48; uppernumbound = 57; % lower and upper bounds for numbers
lowCapbound = 65; upperCapbound = 90; % lower and upper bounds for Cap. letters