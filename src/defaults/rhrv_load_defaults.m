function [] = rhrv_load_defaults( varargin )
%RHRV_LOAD_DEFAULTS Loads an rhrv defaults file, setting it's values as default for all toolbox
%functions. All current parameter defaults will be cleared.
%
%   Usage:
%       rhrv_load_defaults
%       rhrv_load_defaults <defaults_filename>
%       rhrv_load_defaults(defaults_filename, 'param1', value1, 'param2', value2, ...)
%
%   This function loads the parameter values from the default rhrv parameters file and sets them as
%   the default value for the various toolbox functions.
%
%   The second usage form loads the parameter values from an arbitrary rhrv parameters file (.yml).
%   The given file can be a name of a file on the matlab path, or, if it's not found there, it will be
%   interpreted as a path (absolute or relative to pwd).
%
%   The third usage form also allows overriding or adding specific parameters with custom values given
%   to the function. In this form, the filename is optional; the function will also accept just
%   key-value pairs.
%
%   Note: This function always clears all current default parameters in all usage modes.
%

%% Validate input

% Make sure we have parameters
if isempty(varargin)
    varargin = {'defaults'};
end

% Check number of parameters to determine usage type
if mod(length(varargin), 2) ~= 0
    % Odd number of parameters: treat the first as a filename, and the rest as key-values
    params_filename = varargin{1};
    extra_params = varargin(2:end);
else
    % Even number of parameters: no filename, all are key-values
    params_filename = '';
    extra_params = varargin;
end

% Make sure extra params keys are strings
if ~all(cellfun(@ischar, extra_params(1:2:end)))
    error('Extra parameters names must be strings');
end

% Get path to parameters file
if ~isempty(params_filename)
    % Add extension if it's not there
    [~,~,ext] = fileparts(params_filename);
    if isempty(ext)
        params_filename = [params_filename '.yml'];
    elseif strcmpi(ext, '.yml') ~= 0
        error('Only .yml files are supported as parameter files');
    end
    
    % Try to find the parameters file on the MATLAB path, and if it's not there treat it as an
    % absolue or relative path.
    w = which(params_filename);
    if ~isempty(w)
        params_filename = w;
    elseif ~exist(params_filename, 'file')
        error('Cant''t find specified parameters file');
    end
end

%% Set parameters
params = struct;

% If parameters filename was provided, load it
if ~isempty(params_filename)
    params = ReadYaml(params_filename);
end

% Convert simple cell arrays (e.g. {[1],[2]}) to regular vectors. The Yaml parser we're using
% creates such cell arrays when parsing regular arrays ([1, 2]).
params = fix_simple_cell_arrays(params);

% Set the global parameters variable (so the loaded parameters affect the defaults for all toolbox
% functions).
global rhrv_default_values;
rhrv_default_values = params;

% If extra parameters were provided, add them to the parameters (overrides existing)
if ~isempty(extra_params)
    rhrv_set_default(extra_params{:});
end

end

%% Helpers

% A function that recorsively traverses a parameters structure and converts simple cell arrays
% to regular arrays.
function curr_element = fix_simple_cell_arrays(curr_element)

    % If the current element is not a struct, check if we need to fix it
    if ~isstruct(curr_element)
        if iscell(curr_element) && size(curr_element,1) && ~iscellstr(curr_element) && all(cellfun(@isscalar, curr_element))
            % Fix it
            curr_element = cell2mat(curr_element);
        end
        return;
    end

    % If the current element is a parameter structure, update it's value with a fixed value.
    if isfield(curr_element, 'value')
        curr_element.value = fix_simple_cell_arrays(curr_element.value);
        return;
    end

    % Otherwise traverse all fields
    fields = fieldnames(curr_element);
    for ii = 1:length(fields)
        field = fields{ii};
        curr_element.(field) = fix_simple_cell_arrays(curr_element.(field));
    end
end