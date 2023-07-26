classdef CustomMask < handle
    %PODSSettings - PODSGUI project & display settings
    %   An instance of this class holds and determines various 
    %   settings for a single run of PODS GUI
    
    properties
        
        % the name of this custom masking procedure, 'Custom' by default
        Name = 'Custom';

        % array of CustomOperation objects, each defining a specific operation to perform
        Operations CustomOperation

        % array of CustomImage objects, each of the intermediate images resulting from each operation
        Images CustomImage

        % the first image that  subsequent operations build from
        StartingImage

        % CurrentImage idx
        CurrentImageIdx

        % CurrentOperation idx
        CurrentOperationIdx

        % general operation types
        OperationTypes = {...
            'Morphological',...
            'ContrastEnhancement',...
            'ImageFilter',...
            'Arithmetic',...
            'Binarize',...
            'BWMorphology',...
            'EdgeDetection',...
            'Special'...
            };

        % operation sub-types for each operation type
        MorphologicalOperations = {...
            'TopHat',...
            'BottomHat',...
            'Erode',...
            'Dilate',...
            'Open',...
            'Close',...
            'OpenByReconstruction'...
            };

        ContrastEnhancementOperations = {...
            'EnhanceFibers',...
            'LocalBrighten',...
            'AdaptiveHistogramEqualization',...
            'Sharpen',...
            'AdjustContrast',...
            'LocalContrast',...
            'Flatfield',...
            'ReduceHaze',...
            'Scale0To1'...
            };

        ImageFilterOperations = {...
            'Median',...
            'Average',...
            'Gaussian',...
            'Wiener',...
            'Bilateral',...
            'LaplacianOfGaussian',...
            };

        ArithmeticOperations = {...
            '+',...
            '-',...
            '*',...
            '÷'...
            };

        BinarizeOperations = {...
            'Adaptive',...
            'Otsu'...
            };

        SpecialOperations = {...
            'RotatingMaxOpen',...
            'BWRotatingMaxOpen',...
            'BWRotatingMaxOpenAndClose',...
            'LineFilterTransform',...
            'OrientationFilterTransform',...
            'BlindDeconvolution',...
            'Test',...
            'Complement',...
            'ZerocrossEdgesFilled',...
            'CellDetection',...
            'BWAreaOpen',...
            'SobelGradient',...
            }

        EdgeDetectionOperations = {...
            'Sobel',...
            'Prewitt',...
            'Canny',...
            'Roberts',...
            'log',...
            'zerocross',...
            }

        BWMorphologyOperations = {...
            'Skeletonize',...
            }

    end

    properties (Dependent = true)

        OperationsTextDisplay
        ImagesTextDisplay
        nImages
        nOperations
        CurrentOperation
        CurrentImage

        % logical, indicates whether or not this scheme is a valid masking scheme
        isValidMaskingScheme
        % the last grayscale image in the scheme before binarization
        EnhancedImg
        % the idx to the threshold steps
        ThreshStepIdx
        % threshold type (Otsu, adaptive, other, or '')
        ThreshType
    end
    
    methods
        
        % constructor method
        function obj = CustomMask(Name,StartingImage)
            % name of the processing scheme
            obj.Name = Name;
            % the starting image (type CustomImage) of the processing pipeline
            obj.StartingImage = StartingImage;
            % add starting image to the first element of obj.Images
            obj.Images(1) = CustomImage(StartingImage);
            % add the first operation – empty since we don't do anything to create the starting image
            obj.Operations(1) = CustomOperation('Empty','Empty',obj.Images(1),{},{});
        end
        
        % execute the entire scheme
        function Execute(obj)
            % set starting image data
            obj.Images(1).ImageData = obj.StartingImage;
            % execute each operation in the stack
            for OperationIdx = 1:numel(obj.Operations)
                obj.Images(OperationIdx).ImageData = obj.Operations(OperationIdx).Execute();
            end
        end

        % execute a specific operation (obj.Operations(StepIdx))
        function ExecuteStep(obj,StepIdx)
            obj.Images(StepIdx).ImageData = obj.Operations(StepIdx).Execute();
        end

        % execute the scheme starting from a specific step (idx)
        function ExecuteFromStep(obj,StepIdx)
            for step = StepIdx:obj.nOperations
                obj.ExecuteStep(step);
            end
        end

        function AddOperation(obj,OperationType,OperationName,Target,OperationParams,varargin)
            % add new operation
            obj.Operations(end+1) = CustomOperation(OperationType,OperationName,Target,OperationParams,varargin{:});
            % add empty CustomImage to hold the image data when we call obj.execute()
            obj.Images(end+1) = CustomImage([]);
        end

        function EditOperation(obj,OperationIdx,OperationType,OperationName,Target,OperationParams,varargin)
            % we cannot simply replace the operation without preserving its output image
            % we need to save the image object in case any other operations depend on it
            imageToEdit = obj.Images(OperationIdx);
            % edit an existing operation
            obj.Operations(OperationIdx) = CustomOperation(OperationType,OperationName,Target,OperationParams,varargin{:});
            % add empty CustomImage to hold the image data when we call obj.Execute()
            obj.Images(OperationIdx) = imageToEdit;
        end

        function nImages = get.nImages(obj)
            nImages = numel(obj.Images);
        end

        function nOperations = get.nOperations(obj)
            nOperations = numel(obj.Operations);
        end


        function OperationsTextDisplay = get.OperationsTextDisplay(obj)
            OperationsTextDisplay = cell(obj.nOperations,1);
            OperationsTextDisplay{1} = 'None';
            for i = 2:obj.nOperations
                OperationsTextDisplay{i} = obj.Operations(i).OperationName;
            end
            
        end

        function ImagesTextDisplay = get.ImagesTextDisplay(obj)
            ImagesTextDisplay = cell(obj.nImages,1);
            ImagesTextDisplay{1} = 'Image 1 (input)';
            for i = 2:obj.nImages
                switch obj.Operations(i).OperationType
                    case 'Arithmetic'
                        ImagesTextDisplay{i} = ['Image ',num2str(i),...
                            ' (',...
                            'Image ',...
                            num2str(find([obj.Images]==obj.Operations(i).Target(1))),...
                            ' ',obj.Operations(i).OperationName,' ',...
                            ' Image ',...
                            num2str(find([obj.Images]==obj.Operations(i).Target(2))),...
                            ')'...
                            ];
                    otherwise
                        ImagesTextDisplay{i} = ['Image ',num2str(i),...
                            ' (',...
                            obj.Operations(i).OperationName,...
                            ' Image ',...
                            num2str(find([obj.Images]==obj.Operations(i).Target)),...
                            ')'...
                            ];
                end
            end
        end        

        function CurrentOperation = get.CurrentOperation(obj)
            CurrentOperation = obj.Operations(obj.CurrentOperationIdx);
        end

        function CurrentImage = get.CurrentImage(obj)
            CurrentImage = obj.Images(obj.CurrentImageIdx);
        end

        function ClearImageData(obj)
            for i = 1:obj.nImages
                obj.Images(i).ImageData = [];
            end
        end

        function isValidMaskingScheme = get.isValidMaskingScheme(obj)
            isValidMaskingScheme = strcmp(obj.Images(end).ImageClass,'logical');
        end

        function DeleteOperation(obj,operation)
            % index of the operation we want to delete
            opidx = find(obj.Operations==operation);
            % we also need to delete the output image of this operation
            img = obj.Images(opidx);
            % reset the idxs to current image and operation
            if opidx<obj.nImages
                %obj.CurrentImage = obj.Images(opidx+1);
                obj.CurrentImageIdx = opidx;
                obj.CurrentOperationIdx = opidx;
            elseif opidx==obj.nImages
                %obj.CurrentImage = obj.Images(opidx-1);
                obj.CurrentImageIdx = opidx-1;
                obj.CurrentOperationIdx = opidx-1;
            end
            % reconcatenate Operations and Images arrays to account for missing operation
            obj.Operations = [obj.Operations(1:opidx-1) obj.Operations(opidx+1:end)];
            obj.Images = [obj.Images(1:opidx-1) obj.Images(opidx+1:end)];
            % finally, delete the operation and image
            delete(operation);
            delete(img);
            % recursively delete any other operations which this one depended on for its Target
            i = opidx;
            while i <= obj.nOperations
                if any(~isvalid(obj.Operations(i).Target))
                    obj.DeleteOperation(obj.Operations(i));
                else
                    i = i+1;
                end
            end
        end



        function ThreshStepIdx = get.ThreshStepIdx(obj)
            opTypes = cell(1,obj.nOperations);
            [opTypes{1,1:obj.nOperations}] = deal(obj.Operations.OperationName);
            ThreshStepIdx = find(ismember(opTypes,{'Otsu','Adaptive'}));
        end

        function ThreshType = get.ThreshType(obj)
            threshIdx = obj.ThreshStepIdx;
            nThresh = numel(threshIdx);
            % if the last image is logical but neither 'Otsu' or 'Adaptive' were used
            if nThresh < 1 && obj.isValidMaskingScheme
                ThreshType = 'other';
                return
            elseif nThresh == 1
                ThreshType = obj.Operations(threshIdx).OperationName;
                return
            else
                ThreshType = '';
            end
        end

        function EnhancedImg = get.EnhancedImg(obj)
            % the enhanced image is the final grayscale image before the threshold step
            switch obj.ThreshType
                case {'Otsu','Adaptive'}
                    EnhancedImg = obj.Images(obj.ThreshStepIdx-1).ImageData;
                otherwise
                    imageTypes = cell(1,obj.nImages);
                    [imageTypes{1,1:obj.nImages}] = deal(obj.Images.ImageClass);
                    firstLogicalImageIdx = find(ismember(imageTypes,{'logical'}));

                    if ~isempty(firstLogicalImageIdx)
                        EnhancedImg = obj.Images(firstLogicalImageIdx(1)-1);
                    else
                        EnhancedImg = [];
                    end
            end
        end



    end
end