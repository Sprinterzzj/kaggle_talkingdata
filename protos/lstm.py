
import numpy as np
import keras
from keras.models import Model
from keras.layers import Input, Dense, LSTM, Embedding, concatenate, BatchNormalization, Lambda, Activation, GRU, SimpleRNN, RNN
from keras.layers import CuDNNGRU, CuDNNLSTM, StackedRNNCells
from keras.layers.wrappers import TimeDistributed
from keras import backend as K
import tensorflow as tf

MAX_SEQUENCE_LENGTH = 10

LIST_CONV_COL = ['list_avg_app', 'list_avg_device', 'list_avg_os', 'list_avg_hour']

LIST_DATA_COL = ['list_app', 'list_device', 'list_os', 'list_ch',
                 'list_timediff', 'list_hour', 'list_sum_attr', 'list_attr', 'list_avg_ip'] + LIST_CONV_COL

LIST_CAT_COL = ['list_app', 'list_device', 'list_os', 'list_ch', 'list_hour']

LIST_FLOAT_COL = ['list_timediff', 'list_sum_attr', 'list_attr', 'list_avg_ip'] + LIST_CONV_COL

MAP_COL_NUM = {'list_app': 706, 'list_device': 3475, 'list_os': 800, 'list_ch': 202, 'list_hour': 24}


def custom_objective(y_true, y_pred):
    return K.categorical_crossentropy(y_true, y_pred)


def auc(y_true, y_pred):
    score, up_opt = tf.metrics.auc(y_true, y_pred)
    K.get_session().run(tf.local_variables_initializer())
    with tf.control_dependencies([up_opt]):
        score = tf.identity(score)
    return score


def get_lstm2(first_dences=[64, 64, 16],
              is_first_bn=False,
              lstm_size=64,
              lstm_dropout=0.15,
              lstm_recurrent_dropout=0.15,
              # gru_dropout=0.15,
              # gru_recurrent_dropout=0.15,
              # rnn_dropout=0.15,
              # rnn_recurrent_dropout=0.15,
              last_dences=[16, 8],
              is_last_bn=False,
              learning_rate=1.0e-3,
              ):

    inputs = {col: Input(shape=(MAX_SEQUENCE_LENGTH,), dtype='float32' if col in LIST_FLOAT_COL else 'int32',
                         name=f'{col}_input') for col in LIST_DATA_COL}

    one_hots = [Lambda(K.one_hot, arguments={'num_classes': MAP_COL_NUM[col] + 1}, output_shape=(MAX_SEQUENCE_LENGTH, MAP_COL_NUM[col] + 1))(inputs[col])
                for col in LIST_CAT_COL]

    floats = [Lambda(K.expand_dims)(inputs[col]) for col in LIST_FLOAT_COL]
    out = concatenate(one_hots + floats, axis=2)

    for i, size in enumerate(first_dences):
        out = Dense(size, name=f'first_dence_{i}_{size}')(out)
        if is_first_bn:
            out = BatchNormalization(name=f'first_bn_{i}_{size}')(out)
        out = Activation('relu')(out)
    lstm = LSTM(lstm_size,
                dropout=lstm_dropout, recurrent_dropout=lstm_recurrent_dropout,
                return_sequences=True,
                name='lstm', input_shape=(MAX_SEQUENCE_LENGTH, None))(out)

    gru = CuDNNGRU(16, name='gru',
                   input_shape=(MAX_SEQUENCE_LENGTH, None), return_sequences=True)(out)
    rnn = SimpleRNN(16,
                    name='rnn',
                    #dropout=lstm_dropout, recurrent_dropout=lstm_recurrent_dropout,
                    input_shape=(MAX_SEQUENCE_LENGTH, None), return_sequences=True)(out)
    merged = concatenate([lstm, gru, rnn], axis=2)

    for i, size in enumerate(last_dences):
        merged = TimeDistributed(Dense(size, name=f'last_de1_{i}_{size}'), name=f'last_de_{i}_{size}')(merged)
        if is_last_bn:
            merged = TimeDistributed(BatchNormalization(
                name=f'last_bn1_{i}_{size}'), name=f'last_bn_{i}_{size}')(merged)
        merged = TimeDistributed(Activation('relu'))(merged)

    preds = TimeDistributed(Dense(1, activation='sigmoid', name='last1'), name='last')(merged)

    model = Model([inputs[col] for col in LIST_DATA_COL], preds)
    model.compile(loss='binary_crossentropy',
                  optimizer=keras.optimizers.Adam(lr=learning_rate),
                  metrics=[auc])
    return model


def get_lstm3(first_dences=[64, 64, 16],
              is_first_bn=False,
              lstm_size=64,
              lstm_dropout=0.15,
              lstm_recurrent_dropout=0.15,
              # gru_dropout=0.15,
              # gru_recurrent_dropout=0.15,
              # rnn_dropout=0.15,
              # rnn_recurrent_dropout=0.15,
              last_dences=[16, 8],
              is_last_bn=False,
              learning_rate=1.0e-3,
              ):

    inputs = {col: Input(shape=(MAX_SEQUENCE_LENGTH,), dtype='float32' if col in LIST_FLOAT_COL else 'int32',
                         name=f'{col}_input') for col in LIST_FLOAT_COL}

    floats = [Lambda(K.expand_dims)(inputs[col]) for col in LIST_FLOAT_COL]
    out = concatenate(floats, axis=2)

    for i, size in enumerate(first_dences):
        out = Dense(size, name=f'first_dence_{i}_{size}')(out)
        if is_first_bn:
            out = BatchNormalization(name=f'first_bn_{i}_{size}')(out)
        out = Activation('relu')(out)
    lstm = LSTM(lstm_size,
                dropout=lstm_dropout, recurrent_dropout=lstm_recurrent_dropout,
                return_sequences=True,
                name='lstm', input_shape=(MAX_SEQUENCE_LENGTH, None))(out)

    gru = CuDNNGRU(16, name='gru',
                   input_shape=(MAX_SEQUENCE_LENGTH, None), return_sequences=True)(out)
    rnn = SimpleRNN(16,
                    name='rnn',
                    #dropout=lstm_dropout, recurrent_dropout=lstm_recurrent_dropout,
                    input_shape=(MAX_SEQUENCE_LENGTH, None), return_sequences=True)(out)
    merged = concatenate([lstm, gru, rnn], axis=2)

    for i, size in enumerate(last_dences):
        merged = TimeDistributed(Dense(size, name=f'last_de1_{i}_{size}'), name=f'last_de_{i}_{size}')(merged)
        if is_last_bn:
            merged = TimeDistributed(BatchNormalization(
                name=f'last_bn1_{i}_{size}'), name=f'last_bn_{i}_{size}')(merged)
        merged = TimeDistributed(Activation('relu'))(merged)

    preds = TimeDistributed(Dense(1, activation='sigmoid', name='last1'), name='last')(merged)

    model = Model([inputs[col] for col in LIST_FLOAT_COL], preds)
    model.compile(loss='binary_crossentropy',
                  optimizer=keras.optimizers.Adam(lr=learning_rate),
                  metrics=[auc])
    return model


def get_lstm_sin(first_dences=[64, 64, 16],
                 is_first_bn=False,
                 lstm_size=64,
                 lstm_dropout=0.15,
                 lstm_recurrent_dropout=0.15,
                 # gru_dropout=0.15,
                 # gru_recurrent_dropout=0.15,
                 # rnn_dropout=0.15,
                 # rnn_recurrent_dropout=0.15,
                 last_dences=[16, 8],
                 is_last_bn=False,
                 learning_rate=1.0e-3,
                 ):

    inputs = {col: Input(shape=(MAX_SEQUENCE_LENGTH,), dtype='float32' if col in LIST_FLOAT_COL else 'int32',
                         name=f'{col}_input') for col in LIST_FLOAT_COL}

    floats = [Lambda(K.expand_dims)(inputs[col]) for col in LIST_FLOAT_COL]
    out = concatenate(floats, axis=2)

    for i, size in enumerate(first_dences):
        out = Dense(size, name=f'first_dence_{i}_{size}')(out)
        if is_first_bn:
            out = BatchNormalization(name=f'first_bn_{i}_{size}')(out)
        out = Activation('relu')(out)
    lstm = LSTM(lstm_size,
                dropout=lstm_dropout, recurrent_dropout=lstm_recurrent_dropout,
                name='lstm')(out)

    gru = CuDNNGRU(16, name='gru')(out)
    rnn = SimpleRNN(16, name='rnn')(out)

    merged = concatenate([lstm, gru, rnn])

    for i, size in enumerate(last_dences):
        merged = Dense(size, name=f'last_de1_{i}_{size}')(merged)
        if is_last_bn:
            merged = BatchNormalization(name=f'last_bn1_{i}_{size}')(merged)
        merged = Activation('relu')(merged)

    preds = Dense(1, activation='sigmoid', name='last1')(merged)

    model = Model([inputs[col] for col in LIST_FLOAT_COL], preds)
    model.compile(loss='binary_crossentropy',
                  optimizer=keras.optimizers.Adam(lr=learning_rate),
                  metrics=[auc])
    return model


if __name__ == '__main__':
    model = get_lstm_sin()
