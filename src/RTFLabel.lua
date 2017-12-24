local TextService = game:GetService("TextService")

-- Load Roact.
-- Change this to match wherever you installed Roact (or use your module system, etc.)
local Roact = require(game:GetService("ReplicatedStorage"):WaitForChild("Roact"))

local function RTFLabel(props)
    local textNodes = props.TextNodes
    -- We *must* know the size of the frame in order to lay out elements correctly.
    -- Further, we must know the size of the frame in absolute coordinates.
    -- When rendering here we don't know the parent (yet).
    -- Thus, Size must be a Vector2 (for now?).
    local size = props.Size
    local labels = {}
    local lines = {}

    local currentLine = {
        Nodes = {};
        Width = 0;
        Height = 0;
    }

    local function nextLine()
        table.insert(lines, currentLine)
        currentLine = {
            Nodes = {};
            Height = 0;
            Width = 0;
        }
    end

    local function subnode(node, text)
        local copy = {}

        for key, value in pairs(node) do
            copy[key] = value
        end

        copy.Text = text
        return copy
    end

    while #textNodes > 0 do
        local node = textNodes[1]
        table.remove(textNodes, 1)
        local needToWrap = false

        local actualString = ""

        for word in node.Text:gmatch("[^%s]+") do
            local textBounds = TextService:GetTextSize(actualString.." "..word, node.TextSize, node.Font, Vector2.new(100000, 100000))

            if textBounds.X <= size.X - currentLine.Width then
                actualString = actualString.." "..word
            else
                print("break")
                local newNode = subnode(node, node.Text:match((actualString.."(.+)$"):gsub("^%s*", "")))
                table.insert(textNodes, 1, newNode)
                needToWrap = true
                break
            end
        end

        if actualString ~= "" then
            local textBounds = TextService:GetTextSize(actualString, node.TextSize, node.Font, Vector2.new(100000, 100000))
            currentLine.Height = math.max(currentLine.Height, textBounds.Y)
            currentLine.Width = currentLine.Width + textBounds.X

            local lineNode = subnode(node, actualString)
            lineNode.Width = textBounds.X

            table.insert(currentLine.Nodes, lineNode)
        end

        if needToWrap then
            nextLine()
        end
    end

    table.insert(lines, currentLine)

    local y = 0
    for _, line in ipairs(lines) do
        local lineLabels = {}
        local x = 0

        for _, node in ipairs(line.Nodes) do
            local label = Roact.createElement("TextLabel", {
                BackgroundTransparency = 1;
                Text = node.Text;
                Font = node.Font;
                TextSize = node.TextSize;
                TextColor3 = node.TextColor;
                Size = UDim2.new(0, node.Width, 1, 0);
                TextYAlignment = Enum.TextYAlignment.Bottom;
                Position = UDim2.new(0, x, 0, 0);
            })

            x = x + node.Width

            table.insert(lineLabels, label)
        end

        local lineContainer = Roact.createElement("Frame", {
            BackgroundTransparency = 1;
            Size = UDim2.new(0, line.Width, 0, line.Height);
            Position = UDim2.new(0, 0, 0, y);
        }, lineLabels)

        table.insert(labels, lineContainer)

        y = y + line.Height
    end

    local frame = Roact.createElement("Frame", {
        BackgroundTransparency = 1;
        Size = UDim2.new(0, size.X, 0, size.Y);
    }, labels)

    return frame
end

return RTFLabel
