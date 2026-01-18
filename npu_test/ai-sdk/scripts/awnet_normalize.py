import os
import sys
from acuitylib.vsi_nn import VSInn


if __name__ == "__main__":
    name = sys.argv[1]
    nn = VSInn()
    net = nn.create_net()
    nn.load_model(net, name + '.json')
    nn.load_model_inputmeta(net, name + '_inputmeta.yml')
    meta = net.get_input_meta()
    port = meta.databases[0].ports[0]
    if len(port.shape) == 4:
        if port.layout == 'nchw':
            channel = port.shape[1]
        else:
            channel = port.shape[-1]
        if channel == 3 or channel == 1 or channel == 4:
            normalize = sys.argv[2]
            with open(normalize) as f:
                normalizes = f.read().split()
            if len(normalizes) == channel * 2:
                port.preprocess['mean'] = [int(m) for m in normalizes[:channel]]
                port.preprocess['scale'] = [float(s) for s in normalizes[channel:]]
            elif len(normalizes) == channel + 1:
                port.preprocess['mean'] = [int(m) for m in normalizes[:channel]]
                port.preprocess['scale'] = float(normalizes[-1])
    net.update_input_meta(meta)
    nn.save_model_inputmeta(net, name + '_inputmeta.yml')
